/*

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of Object subclasses and maintains additional information about those classes.

public struct Schema
  {
    public let name : String
    public let managedObjectModel : NSManagedObjectModel = .init()
    public private(set) var entitiesByName : [String: EntityInfo] = [:]


    public init(name: String, objectTypes: [Object.Type]) throws
      {
        self.name = name

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
          entity.isAbstract = objectType == objectType.abstractClass
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

        // Extend each NSEntityDescription with the specified relationships and their inverses, which we synthesize where not given explicitly.
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
  }
