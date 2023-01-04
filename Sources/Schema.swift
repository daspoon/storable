/*

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of Object subclasses and maintains additional information about those classes.
///
public struct Schema
  {
    public let name : String
    public let entitiesByName : [String: ManagedEntity]
    public let managedObjectModel : NSManagedObjectModel


    public init(name: String, objectTypes: [ManagedObject.Type]) throws
      {
        self.name = name

        // Perform a post-order traversal on the implied class hierarchy to populate the mapping of names to Entity values and establish the inheritance relations between NSEntityDescriptions.
        var _entitiesByName : [String: ManagedEntity] = [:]
        _ = NSObject.inheritanceHierarchy(with: objectTypes).fold { objectType, subentities in
          guard objectType != ManagedObject.self else { return NSEntityDescription() }
          // Create and register an Entity instance;  it creates an NSEntityDescription with the appropriate name and managedObjectClassName.
          let entity = ManagedEntity(objectType: objectType)
          _entitiesByName[entity.name] = entity
          // Populate the entity's attribute descriptions
          for (name, attribute) in entity.attributes {
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = name
            attributeDescription.type = attribute.attributeType
            attributeDescription.isOptional = attribute.allowsNilValue
            entity.entityDescription.properties.append(attributeDescription)
          }
          // Establish the inheritance relation with subentities, if any.
          entity.entityDescription.subentities = subentities
          // Return the entity description for use by the superentity
          return entity.entityDescription
        }
        entitiesByName = _entitiesByName

        // Extend each NSEntityDescription with the specified relationships and their inverses, which we synthesize where not given explicitly.
        for (sourceName, sourceEntity) in entitiesByName {
          for (relationshipName, relationship) in sourceEntity.relationships {
            // Skip the relationship if it is already defined, which happens when the inverse relationship is processed first.
            guard sourceEntity.entityDescription.relationshipsByName[relationshipName] == nil
              else { continue }
            // Ensure the target entity exists
            let targetName = relationship.relatedEntityName
            guard let targetEntity = entitiesByName[targetName]
              else { throw Exception("relationship \(sourceName).\(relationshipName) has unknown target entity name '\(targetName)'") }
            // Get or synthesize the inverse relationship.
            let inverse : ManagedRelationship
            switch targetEntity.relationships[relationship.inverseName] {
              case .none :
                inverse = relationship.inverse(for: sourceName)
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
            forwardDescription.destinationEntity = targetEntity.entityDescription
            forwardDescription.inverseRelationship = inverseDescription
            forwardDescription.deleteRule = relationship.deleteRule
            forwardDescription.rangeOfCount = relationship.arity.rangeOfCount
            inverseDescription.name = relationship.inverseName
            inverseDescription.destinationEntity = sourceEntity.entityDescription
            inverseDescription.inverseRelationship = forwardDescription
            inverseDescription.deleteRule = inverse.deleteRule
            inverseDescription.rangeOfCount = inverse.arity.rangeOfCount
            // Add the NSRelationshipDescriptions to the corresponding NSEntityDescriptions
            sourceEntity.entityDescription.properties.append(forwardDescription)
            targetEntity.entityDescription.properties.append(inverseDescription)
          }
        }

        // Create and populate an managed object model with the defined entities
        managedObjectModel = .init()
        managedObjectModel.entities = entitiesByName.map { $0.value.entityDescription }
      }
  }
