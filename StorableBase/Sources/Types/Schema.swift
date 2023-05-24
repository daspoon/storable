/*

  Created by David Spooner

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of ManagedObject subclasses and maintains additional information about those classes.

public struct Schema
  {
    /// A convenience type pairing the data structures generated on demand: the managed object model and the mapping of entity names to ClassInfo structures.
    public typealias RuntimeInfo = (managedObjectModel: NSManagedObjectModel, classInfoByName: [String: EntityTree])


    /// The ManagedObject classes given on initialization, organized as a tree closed under inheritance.
    private let entityTree : EntityTree

    /// An explicit version identifier optionally assigned on initialization.
    public let versionId : String?

    /// The name of the implicit entity added to each generated object model.
    static let versioningEntityName = "$Schema"


    /// Create a new instance with a given list of ManagedObject subclasses and an optional model version identifier.
    public init(versionId: String? = nil, objectTypes: [ManagedObject.Type]) throws
      {
        self.versionId = versionId
        self.entityTree = try EntityTree(objectTypes: objectTypes)
      }


    /// Create the pairing of managed object model and entity mapping implied by the schema. The given versionId must be the one maintained by the instance unless none was given on initialization.
    public func createRuntimeInfo(withVersionId versionId: String) throws -> RuntimeInfo
      {
        precondition(self.versionId == nil || self.versionId == .some(versionId))

        // Complete the entity tree to construct the hierarchy of entity descriptions and obtain the mapping of entity names to subtrees.
        let classInfoByName = try entityTree.complete()

        // Extend each NSEntityDescription with the specified attributes.
        for (_, classInfo) in classInfoByName {
          for (name, attribute) in classInfo.attributes {
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = name
            attributeDescription.type = attribute.attributeType
            attributeDescription.isOptional = attribute.isOptional
            attributeDescription.valueTransformerName = attribute.valueTransformerName?.rawValue
            attributeDescription.defaultValue = attribute.defaultValue
            attributeDescription.renamingIdentifier = attribute.renamingIdentifier
            classInfo.entityDescription.properties.append(attributeDescription)
          }
        }

        // Extend each NSEntityDescription with the specified relationships and their inverses, which must be given explicitly.
        for (sourceName, sourceInfo) in classInfoByName {
          for (relationshipName, relationship) in sourceInfo.relationships {
            // Skip the relationship if it is already defined, which happens when the inverse relationship is processed first.
            guard sourceInfo.entityDescription.relationshipsByName[relationshipName] == nil
              else { continue }
            // Ensure the target entity exists
            let targetName = relationship.relatedEntityName
            guard let targetInfo = classInfoByName[targetName]
              else { throw Exception("relationship \(sourceName).\(relationshipName) has unknown target entity name '\(targetName)'") }
            // Get the inverse relationship from either a declared property on the related entity xor extra detail on the source property...
            let inverse : Relationship
            switch (targetInfo.relationships[relationship.inverse.name], relationship.inverse(toEntityName: sourceName)) {
              case (.some(let explicit), .none) :
                inverse = explicit
              case (.none, .some(let implicit)) :
                inverse = implicit
              case (.none, .none) :
                throw Exception("inverse \(targetName).\(relationship.inverse.name) of \(sourceName).\(relationshipName) is undefined")
              case (.some, .some) :
                throw Exception("inverse \(targetName).\(relationship.inverse.name) of \(sourceName).\(relationshipName) has multiple definitions")
            }
            // Create NSRelationshipDescriptions for the relationship pair.
            let (forwardDescription, inverseDescription) = (NSRelationshipDescription(), NSRelationshipDescription())
            forwardDescription.name = relationship.name
            forwardDescription.destinationEntity = targetInfo.entityDescription
            forwardDescription.inverseRelationship = inverseDescription
            forwardDescription.deleteRule = .init(relationship.deleteRule)
            forwardDescription.rangeOfCount = relationship.range
            inverseDescription.name = relationship.inverse.name
            inverseDescription.destinationEntity = sourceInfo.entityDescription
            inverseDescription.inverseRelationship = forwardDescription
            inverseDescription.deleteRule = .init(inverse.deleteRule)
            inverseDescription.rangeOfCount = inverse.range
            // Add the NSRelationshipDescriptions to the corresponding NSEntityDescriptions
            sourceInfo.entityDescription.properties.append(forwardDescription)
            targetInfo.entityDescription.properties.append(inverseDescription)
          }
        }

        // Define the fetched properties of each entity...
        for sourceInfo in classInfoByName.values {
          for (propertyName, fetchedPropertyInfo) in sourceInfo.fetchedProperties {
            let fetchedEntityName = fetchedPropertyInfo.fetchRequest.entityName! // TODO: eliminate optional
            guard let fetchedEntity = classInfoByName[fetchedEntityName]?.entityDescription else { throw Exception("unknown entity '\(fetchedEntityName)'") }
            // Note that the fetched property description must have a resolved entity
            fetchedPropertyInfo.fetchRequest.entity = fetchedEntity
            let fetchedPropertyDescription = NSFetchedPropertyDescription()
            fetchedPropertyDescription.name = propertyName
            fetchedPropertyDescription.fetchRequest = fetchedPropertyInfo.fetchRequest
            sourceInfo.entityDescription.properties.append(fetchedPropertyDescription)
          }
        }

        // Create the object model with the generated entity descriptions.
        let objectModel : NSManagedObjectModel = .init()
        objectModel.entities = classInfoByName.values.map { $0.entityDescription }

        // Add the entity used to distinguish schema versions; this entity is not exposed in classInfoByName.
        let versionEntity = NSEntityDescription()
        versionEntity.name = Self.versioningEntityName
        versionEntity.versionHashModifier = versionId
        objectModel.entities.append(versionEntity)

        return (objectModel, classInfoByName)
      }


    mutating func withEntityNamed(_ entityName: String, update: (inout Entity) -> Void)
      {
        guard let subtree = entityTree.subtreesByName[entityName] else { preconditionFailure("invalid argument: \(entityName)") }
        subtree.withEntity(update: update)
      }


    /// Return the steps required to migrate the object model of the previous schema version to the receiver's object model.
    func migrationSteps(to targetModel: NSManagedObjectModel, from sourceModel: NSManagedObjectModel, of sourceSchema: Schema, using migration: Migration) throws -> [Migration.Step]
      {
        let customizationInfo = try Self.customizationInfoForMigration(from: sourceSchema, to: self)

        let steps : [Migration.Step]
        switch (customizationInfo.requiresMigrationScript, migration.script) {
          case (false, .none) :
            // An implicit migration to the target model is sufficient.
            steps = [.lightweight(targetModel)]

          case (_, .some(let script)) :
            // A migration script is necessary: extend the intermediate schema with a MigrationScriptMarker,
            try customizationInfo.intermediateSchema.entityTree.addObjectType(Migration.ScriptMarker.self)
            // construct a version identifier for the intermediate model,
            let versionId = sourceModel.versionId + " -> " + targetModel.versionId // NOTE: we have no means to ensure this identifier is unique
            // generate the intermediate object model,
            let intermediateModel = try customizationInfo.intermediateSchema.createRuntimeInfo(withVersionId: versionId).managedObjectModel
            // and set renaming identifiers on target attributes subject to storage type changes.
            for (entityName, attributeName) in customizationInfo.renamedTargetAttributes {
              targetModel.entitiesByName[entityName]!.attributesByName[attributeName]!.renamingIdentifier = Self.renameNew(attributeName)
            }
            steps = [.lightweight(intermediateModel), .script(script, migration.idempotent), .lightweight(targetModel)]

          case (true, .none) :
            throw Exception("a migration script is required")
        }

        return steps
      }


    public static func renameOld(_ name: String) -> String
      { "$\(name)_old" }

    public static func renameNew(_ name: String) -> String
      { "$\(name)_new" }


    /// CustomMigrationInfo maintains an intermediate schema to bridge between adjacent schema versions, along with auxiliary data.
    struct CustomMigrationInfo
      {
        /// The source schema with additive modifications.
        var intermediateSchema : Schema
        /// Indicates whether or not a migration script is required
        var requiresMigrationScript : Bool = false
        /// Indicates the attributes of the target schema which have alternate names in the intermediate schema.
        var renamedTargetAttributes : [(entityName: String, attributeName: String)] = []
      }


    /// Returns a summary of the differences between given source and target schemas.
    static func customizationInfoForMigration(from sourceSchema: Schema, to targetSchema: Schema) throws -> CustomMigrationInfo
      {
        // The intermediate schema starts as a copy of the source schema.
        var info = CustomMigrationInfo(intermediateSchema: sourceSchema)

        // Traverse the differences between the source and target schemas, making changes to the intermediate schema where necessary and noting when a migration script is required.
        if let schemaDiff = try targetSchema.difference(from: sourceSchema) {
          // Add each new entity to the intermediate schema; these changes don't necessarily require a migration script.
          for entityName in schemaDiff.added {
            let entityInfo = targetSchema.entityTree.subtreesByName[entityName]!
            try info.intermediateSchema.entityTree.addObjectType(entityInfo.managedObjectClass, entity: entityInfo.entity)
          }
          // Modify the entities of the intermediate schema to reflect the additive differences between each entity common to source and target schemas.
          for (entityName, entityDiff) in schemaDiff.modified {
            let targetObjectInfo = targetSchema.entityTree.subtreesByName[entityName]!
            let sourceObjectInfo = sourceSchema.entityTree.subtreesByName[targetObjectInfo.entity.renamingIdentifier ?? entityName]!
            // Extend the intermediate entity to account for added attributes; these require migration scripts when non-optional.
            for attrName in entityDiff.attributesDifference.added {
              info.intermediateSchema.withEntityNamed(entityName) {
                let targetAttr = targetObjectInfo.entity.attributes[attrName]!
                $0.addAttribute(targetAttr)
                if !(targetAttr.isOptional || targetAttr.defaultValue != nil) {
                  info.requiresMigrationScript = true
                }
              }
            }
            // Update the intermediate entity to account for modified attributes, where necessary.
            for (attrName, changes) in entityDiff.attributesDifference.modified {
              let targetAttr = targetObjectInfo.entity.attributes[attrName]!
              let sourceAttr = sourceObjectInfo.entity.attributes[targetAttr.renamingIdentifier ?? attrName]!
              for change in changes {
                switch change {
                  case .isOptional where targetAttr.isOptional == false :
                    // Becoming non-optional requires ensuring each affected attribute has a non-nil value.
                    info.requiresMigrationScript = true
                  case .type :
                    // Changing value type requires that the intermediate contains both old and new attributes renamed, and with the new attribute marked optional.
                    info.intermediateSchema.withEntityNamed(entityName) {
                      $0.removeAttributeNamed(sourceAttr.name)
                      $0.addAttribute(sourceAttr.copy { $0.name = Self.renameOld(attrName); $0.renamingIdentifier = sourceAttr.name })
                      $0.addAttribute(targetAttr.copy { $0.name = Self.renameNew(attrName); $0.isOptional = true })
                    }
                    // Remember to restore the new attribute name in the target model.
                    info.renamedTargetAttributes.append((entityName, attrName))
                    info.requiresMigrationScript = true
                  default :
                    continue
                }
              }
            }
            // Extend the intermediate entity to account for added relationships; these require migration scripts when non-optional.
            for relName in entityDiff.relationshipsDifference.added {
              info.intermediateSchema.withEntityNamed(entityName) {
                let targetRel = targetObjectInfo.entity.relationships[relName]!
                $0.addRelationship(targetRel)
                if !(targetRel.range.contains(0)) {
                  info.requiresMigrationScript = true
                }
              }
            }
            // Update the intermediate entity to account for modified relationships, where necessary.
            for (relName, changes) in entityDiff.relationshipsDifference.modified {
              let targetRel = targetObjectInfo.entity.relationships[relName]!
              let sourceRel = sourceObjectInfo.entity.relationships[targetRel.renamingIdentifier ?? relName]!
              for change in changes {
                switch change {
                  case .rangeOfCount :
                    // If the new range does not contain the old range then it must be relaxed in the intermediate model and a script must be run to update each instance appropriately.
                    let (sourceRange, targetRange) = (sourceRel.range, targetRel.range)
                    if targetRange.contains(sourceRange) == false {
                      info.intermediateSchema.withEntityNamed(entityName) {
                        $0.withRelationshipNamed(relName) { $0.range = min(sourceRange.lowerBound, targetRange.lowerBound) ... max(sourceRange.upperBound, targetRange.upperBound) }
                      }
                      info.requiresMigrationScript = true
                    }
                  case .relatedEntityName, .inverseName :
                    // We require a migration script, but the effect on the intermediate schema is determined by the differences which must accompany such changes.
                    info.requiresMigrationScript = true
                  default :
                    continue
                }
              }
            }
          }
        }

        return info
      }
  }


extension Schema : Diffable
  {
    public func difference(from old: Schema) throws -> Dictionary<String, Entity>.Difference?
      {
        // assert: predecessor == .some(old)
        let entitiesByName = entityTree.subtreesByName.mapValues { $0.entity }
        let oldEntitiesByName = old.entityTree.subtreesByName.mapValues { $0.entity }
        return try entitiesByName.difference(from: oldEntitiesByName, moduloRenaming: \.renamingIdentifier)
      }
  }
