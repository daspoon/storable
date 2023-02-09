/*

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of Object subclasses and maintains additional information about those classes.

public struct Schema
  {
    public typealias RuntimeInfo = (managedObjectModel: NSManagedObjectModel, entityInfoByName: [String: EntityInfo])

    public let name : String
    private var inheritanceHierarchy : InheritanceHierarchy<Object> = .init()
    public private(set) var objectInfoByName : [String: ObjectInfo] = [:]

    /// The version string is set by DataStore.openWith(schema:migrations:), and is used as versionHashModifier for the $Schema entity which is implicitly added to the generated object model.
    internal var version : String?


    public init(name: String = "schema", objectTypes: [Object.Type]) throws
      {
        self.name = name

        for objectType in objectTypes {
          try self.addObjectType(objectType)
        }
      }


    /// Add a new object type, optionally providing an pre-existing ObjectInfo instance.
    private mutating func addObjectType(_ givenType: Object.Type, objectInfo givenInfo: ObjectInfo? = nil) throws
      {
        precondition(objectInfoByName[givenType.entityName] == nil && givenInfo.map({$0.managedObjectClass == givenType}) != .some(false), "invalid argument")

        try inheritanceHierarchy.add(givenType) { newType in
          let entityName = newType.entityName
          let existingInfo = objectInfoByName[entityName]
          guard existingInfo == nil else { throw Exception("entity name \(entityName) is defined by both \(existingInfo!.managedObjectClass) and \(newType)") }
          objectInfoByName[entityName] = try ObjectInfo(objectType: newType)
        }
      }


    /// Add the given ObjectInfo instance for an object type which does not already belong to the schema.
    public mutating func addObjectInfo(_ objectInfo: ObjectInfo) throws
      {
        try addObjectType(objectInfo.managedObjectClass, objectInfo: objectInfo)
      }


    public func createRuntimeInfo() throws -> RuntimeInfo
      {
        // Perform a post-order traversal on the ObjectInfo hierarchy to create an entity description for each class, establish inheritance between entities, and populate entityInfoByName...
        var entityInfoByName : [String: EntityInfo] = [:]
        _ = inheritanceHierarchy.fold { (objectType: Object.Type, subentities: [NSEntityDescription]) -> NSEntityDescription in
          // Ignore the root class (i.e. Object) which is not modeled.
          guard objectType != Object.self else { return .init() }
          // Get the corresponding ObjectInfo
          guard let objectInfo = objectInfoByName[objectType.entityName] else { fatalError() }
          // Create an NSEntityDescription
          let entityDescription = NSEntityDescription()
          entityDescription.name = objectInfo.name
          entityDescription.managedObjectClassName = NSStringFromClass(objectType)
          entityDescription.isAbstract = objectType.isAbstract
          entityDescription.subentities = subentities
          // Add a registry entry
          entityInfoByName[objectInfo.name] = EntityInfo(objectInfo, entityDescription)
          // Return the generated entity
          return entityDescription
        }

        // Extend each NSEntityDescription with the specified attributes.
        for (_, entityInfo) in entityInfoByName {
          for (name, attribute) in entityInfo.objectInfo.attributes {
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = name
            attributeDescription.type = attribute.attributeType
            attributeDescription.isOptional = attribute.allowsNilValue
            attributeDescription.valueTransformerName = attribute.valueTransformerName?.rawValue
            attributeDescription.defaultValue = attribute.defaultValue?.storedValue()
            attributeDescription.renamingIdentifier = attribute.previousName
            entityInfo.entityDescription.properties.append(attributeDescription)
          }
        }

        // Extend each NSEntityDescription with the specified relationships and their inverses, which must be given explicitly.
        for (sourceName, sourceInfo) in entityInfoByName {
          for (relationshipName, relationship) in sourceInfo.objectInfo.relationships {
            // Skip the relationship if it is already defined, which happens when the inverse relationship is processed first.
            guard sourceInfo.entityDescription.relationshipsByName[relationshipName] == nil
              else { continue }
            // Ensure the target entity exists
            let targetName = relationship.relatedEntityName
            guard let targetInfo = entityInfoByName[targetName]
              else { throw Exception("relationship \(sourceName).\(relationshipName) has unknown target entity name '\(targetName)'") }
            // Get the inverse relationship (TODO: synthesize if possible)
            let inverse : RelationshipInfo
            switch targetInfo.objectInfo.relationships[relationship.inverseName] {
              case .none :
                throw Exception("specified inverse \(targetName).\(relationship.inverseName) of \(sourceName).\(relationshipName) is undefined")
              case .some(let explicit) :
                guard explicit.relatedEntityName == sourceName
                  else { throw Exception("relatedEntityName '\(explicit.relatedEntityName)' of \(targetName).\(relationship.inverseName) is inconsistent with specified inverse \(sourceName).\(relationshipName)") }
                guard explicit.inverseName == relationship.name
                  else { throw Exception("inverseName '\(explicit.inverseName)' of \(targetName).\(relationship.inverseName) is inconsistent with specified inverse \(sourceName).\(relationshipName)") }
                inverse = explicit
            }
            // Create NSRelationshipDescriptions for the relationship pair.
            let (forwardDescription, inverseDescription) = (NSRelationshipDescription(), NSRelationshipDescription())
            forwardDescription.name = relationship.name
            forwardDescription.destinationEntity = targetInfo.entityDescription
            forwardDescription.inverseRelationship = inverseDescription
            forwardDescription.deleteRule = relationship.deleteRule
            forwardDescription.rangeOfCount = relationship.arity
            inverseDescription.name = relationship.inverseName
            inverseDescription.destinationEntity = sourceInfo.entityDescription
            inverseDescription.inverseRelationship = forwardDescription
            inverseDescription.deleteRule = inverse.deleteRule
            inverseDescription.rangeOfCount = inverse.arity
            // Add the NSRelationshipDescriptions to the corresponding NSEntityDescriptions
            sourceInfo.entityDescription.properties.append(forwardDescription)
            targetInfo.entityDescription.properties.append(inverseDescription)
          }
        }

        // Define the fetched properties of each entity...
        for sourceInfo in entityInfoByName.values {
          for (propertyName, fetchedPropertyInfo) in sourceInfo.objectInfo.fetchedProperties {
            let fetchedEntityName = fetchedPropertyInfo.fetchRequest.entityName! // TODO: eliminate optional
            guard let fetchedEntity = entityInfoByName[fetchedEntityName]?.entityDescription else { throw Exception("unknown entity '\(fetchedEntityName)'") }
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
        objectModel.entities = entityInfoByName.values.map { $0.entityDescription }

        // Add the entity used to distinguish schema versions; this entity is not exposed in entityInfoByName.
        let versionEntity = NSEntityDescription()
        versionEntity.name = "$Schema"
        versionEntity.versionHashModifier = version
        objectModel.entities.append(versionEntity)

        return (objectModel, entityInfoByName)
      }


    mutating func withEntityNamed(_ entityName: String, update: (inout ObjectInfo) -> Void)
      { update(&objectInfoByName[entityName]!) }


    /// Return the steps required to migrate the object model of the previous schema version to the receiver's object model.
    func migrationSteps(from sourceModel: NSManagedObjectModel, of sourceSchema: Schema, to targetModel: NSManagedObjectModel, using migrationScript: Migration.Script?) throws -> [Migration.Step]
      {
        var customizationInfo = try Self.customizationInfoForMigration(from: sourceSchema, to: self)

        let steps : [Migration.Step]
        switch (customizationInfo.requiresMigrationScript, migrationScript) {
          case (false, .none) :
            // An implicit migration to the target model is sufficient.
            steps = [.lightweight(targetModel)]

          case (_, .some(let migrationScript)) :
            // A migration script is necessary: extend the intermediate schema with a MigrationScriptMarker,
            try customizationInfo.intermediateSchema.addObjectType(MigrationScriptMarker.self)
            // generate the intermediate object model,
            let intermediateModel = try customizationInfo.intermediateSchema.createRuntimeInfo().managedObjectModel
            // and set renaming identifiers on target attributes subject to storage type changes.
            for (entityName, attributeName) in customizationInfo.renamedTargetAttributes {
              targetModel.entitiesByName[entityName]!.attributesByName[attributeName]!.renamingIdentifier = Self.renameNew(attributeName)
            }
            steps = [.lightweight(intermediateModel), .script(migrationScript), .lightweight(targetModel)]

          case (true, .none) :
            throw Exception("a migration script is required")
        }

        return steps
      }


    public static func renameOld(_ name: String) -> String
      { "$\(name)_old" }

    public static func renameNew(_ name: String) -> String
      { "$\(name)_new" }


    struct CustomMigrationInfo
      {
        /// The source schema with additive modifications.
        var intermediateSchema : Schema
        /// Indicates whether or not a migration script is required
        var requiresMigrationScript : Bool = false
        /// Indicates the attributes of the target schema which have alternate names in the intermediate schema.
        var renamedTargetAttributes : [(entityName: String, attributeName: String)] = []
      }


    /// Return the intermediate schema required for a custom migration between the given source and target schemas, or nil if lightweight migration is sufficient.
    static func customizationInfoForMigration(from sourceSchema: Schema, to targetSchema: Schema) throws -> CustomMigrationInfo
      {
        // The intermediate schema starts as a copy of the source schema.
        var info = CustomMigrationInfo(intermediateSchema: sourceSchema)

        // Traverse the differences between the source and target schemas, making changes to the intermediate schema where necessary and noting when a migration script is required.
        if let schemaDiff = try targetSchema.difference(from: sourceSchema) {
          // Add each new entity to the intermediate schema; these changes don't necessarily require a migration script.
          for entityName in schemaDiff.added {
            try info.intermediateSchema.addObjectInfo(targetSchema.objectInfoByName[entityName]!)
          }
          // Modify the entities of the intermediate schema to reflect the additive differences between each entity common to source and target schemas.
          for (entityName, entityDiff) in schemaDiff.modified {
            let targetObjectInfo = targetSchema.objectInfoByName[entityName]!
            let sourceObjectInfo = sourceSchema.objectInfoByName[/* targetObjectInfo.previousName ?? */entityName]! // TODO: account for renaming entities
            // Extend the intermediate entity to account for added attributes.
            for attrName in entityDiff.attributesDifference.added {
              info.intermediateSchema.withEntityNamed(entityName) {
                $0.addAttribute(targetObjectInfo.attributes[attrName]!)
              }
            }
            // Update the intermediate entity to account for modified attributes, where necessary.
            for (attrName, changes) in entityDiff.attributesDifference.modified {
              let targetAttr = targetObjectInfo.attributes[attrName]!
              let sourceAttr = sourceObjectInfo.attributes[targetAttr.previousName ?? attrName]!
              for change in changes {
                switch change {
                  case .isOptional where targetAttr.allowsNilValue == false :
                    // Becoming non-optional requires ensuring each affected attribute has a non-nil value.
                    info.requiresMigrationScript = true
                  case .type :
                    // Changing value type requires that the intermediate contains both old and new attributes renamed, and with the new attribute marked optional.
                    info.intermediateSchema.withEntityNamed(entityName) {
                      $0.removeAttributeNamed(sourceAttr.name)
                      $0.addAttribute(sourceAttr.copy { $0.name = Self.renameOld(attrName); $0.previousName = sourceAttr.name })
                      $0.addAttribute(targetAttr.copy { $0.name = Self.renameNew(attrName); $0.allowsNilValue = true })
                    }
                    // Remember to restore the new attribute name in the target model.
                    info.renamedTargetAttributes.append((entityName, attrName))
                    info.requiresMigrationScript = true
                  default :
                    continue
                }
              }
            }
            // Extend the intermediate entity to account for added relationships.
            for relName in entityDiff.relationshipsDifference.added {
              info.intermediateSchema.withEntityNamed(entityName) {
                $0.addRelationship(targetObjectInfo.relationships[relName]!)
              }
            }
            // Update the intermediate entity to account for modified relationships, where necessary.
            for (relName, changes) in entityDiff.relationshipsDifference.modified {
              let targetRel = targetObjectInfo.relationships[relName]!
              let sourceRel = sourceObjectInfo.relationships[targetRel.previousName ?? relName]!
              for change in changes {
                switch change {
                  case .rangeOfCount :
                    // If the new arity does not contain the old arity then we must relax arity in the intermediate model and run a script to update each instance appropriately.
                    let (sourceArity, targetArity) = (sourceRel.arity, targetRel.arity)
                    if targetArity.contains(sourceArity) == false {
                      info.intermediateSchema.withEntityNamed(entityName) {
                        $0.withRelationshipNamed(relName) { $0.arity = min(sourceArity.lowerBound, targetArity.lowerBound) ... max(sourceArity.upperBound, targetArity.upperBound) }
                      }
                      info.requiresMigrationScript = true
                    }
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
    public func difference(from old: Schema) throws -> Dictionary<String, ObjectInfo>.Difference?
      {
        // assert: predecessor == .some(old)
        try objectInfoByName.difference(from: old.objectInfoByName, moduloRenaming: \.previousName)
      }
  }
