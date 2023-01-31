/*

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of Object subclasses and maintains additional information about those classes.

public struct Schema
  {
    public let name : String
    public let version : Int
    public let managedObjectModel : NSManagedObjectModel = .init()
    public private(set) var entitiesByName : [String: EntityInfo] = [:]

    // Note: maintain optional predecessor as a list since structs can't contain optional values of Self...
    private let predecessors : [Schema]


    public init(name: String, predecessor: Schema? = nil, objectTypes: [Object.Type]) throws
      {
        self.name = name
        self.version = (predecessor?.version ?? 0) + 1
        self.predecessors = [predecessor].compactMap {$0}

        // Perform a post-order traversal on the implied class hierarchy to populate entitiesByName.
        _ = try InheritanceHierarchy(containing: objectTypes).fold { (objectType, subentities) -> NSEntityDescription in
          // Ignore the root class which is not modeled.
          guard objectType != Object.self else { return .init() }
          // Create an ObjectInfo containing the managed property wrappers
          let objectInfo = try ObjectInfo(objectType: objectType)
          // Create an NSEntityDescription
          let entity = NSEntityDescription()
          entity.name = objectInfo.name
          entity.managedObjectClassName = NSStringFromClass(objectInfo.managedObjectClass)
          entity.isAbstract = objectType.isAbstract
          entity.subentities = subentities
          // Extend entitiesByName
          entitiesByName[objectInfo.name] = EntityInfo(objectInfo, entity)
          return entity
        }

        // Extend each NSEntityDescription with the specified attributes.
        for (_, entityInfo) in entitiesByName {
          for (name, attribute) in entityInfo.objectInfo.attributes {
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = name
            attributeDescription.type = attribute.attributeType
            attributeDescription.isOptional = attribute.allowsNilValue
            attributeDescription.valueTransformerName = attribute.valueTransformerName?.rawValue
            attributeDescription.defaultValue = attribute.defaultValue?.storedValue()
            entityInfo.entityDescription.properties.append(attributeDescription)
          }
        }

        // Extend each NSEntityDescription with the specified relationships and their inverses, which must be given explicitly.
        for (sourceName, sourceInfo) in entitiesByName {
          for (relationshipName, relationship) in sourceInfo.objectInfo.relationships {
            // Skip the relationship if it is already defined, which happens when the inverse relationship is processed first.
            guard sourceInfo.entityDescription.relationshipsByName[relationshipName] == nil
              else { continue }
            // Ensure the target entity exists
            let targetName = relationship.relatedEntityName
            guard let targetInfo = entitiesByName[targetName]
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
        for sourceInfo in entitiesByName.values {
          for (propertyName, fetchedPropertyInfo) in sourceInfo.objectInfo.fetchedProperties {
            let fetchedEntityName = fetchedPropertyInfo.fetchRequest.entityName! // TODO: eliminate optional
            guard let fetchedEntity = entitiesByName[fetchedEntityName]?.entityDescription else { throw Exception("unknown entity '\(fetchedEntityName)'") }
            // Note that the fetched property description must have a resolved entity
            fetchedPropertyInfo.fetchRequest.entity = fetchedEntity
            let fetchedPropertyDescription = NSFetchedPropertyDescription()
            fetchedPropertyDescription.name = propertyName
            fetchedPropertyDescription.fetchRequest = fetchedPropertyInfo.fetchRequest
            sourceInfo.entityDescription.properties.append(fetchedPropertyDescription)
          }
        }

        // Add the defined entities to the object model
        managedObjectModel.entities = entitiesByName.map { $0.value.entityDescription }
      }


    var predecessor : Schema?
      { predecessors.isEmpty ? nil : predecessors[0] }


    /// Return the list of steps required to migrate a store from the previous version.
    func migrationPath(forStoreMetadata metadata: [String: Any]) throws -> (sourceModel: NSManagedObjectModel, migrationSteps: [MigrationStep])
      {
        // If our model matches the given metadata then we're done
        guard managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false
          else { return (managedObjectModel, []) }

        // Otherwise we must have a predecessor which determines the source model and initial sequence of steps.
        guard let prefix = try predecessor?.migrationPath(forStoreMetadata: metadata)
          else { throw Exception("no compatible schema version") }

        // Note: if the receiver has a script then its contribution will have the form [.lightweight(intermediate), .script(...), .lightweight(managedObjectModel)],
        // where intermediate is the predecessor's object model plus the additive changes leading to current object model, plus the ScriptMarker entity.
        let additionalSteps : [MigrationStep] = [.lightweight(managedObjectModel)]

        // Append our contribution to the path returned by the predecessory.
        return (prefix.sourceModel, prefix.migrationSteps + additionalSteps)
      }
  }
