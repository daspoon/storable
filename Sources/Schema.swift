/*

  TODO: extend to support inheritance
    - build a tree containing the given classes together with their superclasses rooted at Object.
    - set the subentities of each NSEntityDescription appropriately...

*/

import CoreData


public struct Schema
  {
    public let name : String
    public let stateEntityName : String
    public let entitiesByName : [String: Entity]
    public let managedObjectModel : NSManagedObjectModel


    public init(name: String, stateEntityName: String = "State", objectTypes: [Object.Type]) throws
      {
        self.name = name
        self.stateEntityName = stateEntityName

        // Map the name of each class to an Entity instance, which maintains its NSEntityDescription configured with the declared attributes.
        entitiesByName = .init(uniqueKey: \.name, elements: objectTypes.map {Entity(objectType: $0)})

        // Extend each NSEntityDescription with the specified relationships and their inverses, which we synthesize where not given explicitly.
        for (sourceName, sourceEntity) in entitiesByName {
          for (relationshipName, property) in sourceEntity.properties {
            guard let relationship = property as? Relationship else { continue }
            // Skip the relationship if it is already defined, which happens when the inverse relationship is processed first.
            guard sourceEntity.entityDescription.relationshipsByName[relationshipName] == nil
              else { continue }
            // Ensure the target entity exists
            let targetName = relationship.relatedEntityName
            guard let targetEntity = entitiesByName[targetName]
              else { throw Exception("relationship \(sourceName).\(relationshipName) has unknown target entity name '\(targetName)'") }
            // Get or synthesize the inverse relationship.
            let inverse : Relationship
            switch targetEntity.properties[relationship.inverseName] as? Relationship {
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
