/*

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of Object subclasses and maintains additional information about those classes.
///
public struct Schema
  {
    public let name : String
    public let managedObjectModel : NSManagedObjectModel
    public private(set) var entitiesByName : [String: EntityInfo] = [:]


    public init(name: String, objectTypes: [Object.Type]) throws
      {
        self.name = name

        // Perform a post-order traversal on the implied class hierarchy to populate the mapping of entity names to EntityInfo.
        entitiesByName = try NSObject.inheritanceHierarchy(with: objectTypes).fold({try Self.processObjectType($0, subtreeResults: $1)}).1

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
            // Get or synthesize the inverse relationship.
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

        // Create and populate an managed object model with the defined entities
        managedObjectModel = .init()
        managedObjectModel.entities = entitiesByName.map { $0.value.entityDescription }
      }


    private static func processObjectType(_ objectType: Object.Type, subtreeResults: [(EntityInfo, [String: EntityInfo])]) throws -> (EntityInfo, [String: EntityInfo])
      {
        // Create an ObjectInfo containing the managed property wrappers
        let objectInfo = ObjectInfo(objectType: objectType)

        // Create an entity description for CoreData
        let entity = NSEntityDescription()
        entity.name = objectInfo.name
        entity.managedObjectClassName = objectInfo.name
        entity.isAbstract = objectType == objectType.abstractClass

        // Populate the entity's attribute descriptions
        for (name, attribute) in objectInfo.attributes {
          let attributeDescription = NSAttributeDescription()
          attributeDescription.name = name
          attributeDescription.type = attribute.attributeType
          attributeDescription.isOptional = attribute.allowsNilValue
          attributeDescription.valueTransformerName = attribute.valueTransformerName?.rawValue
          attributeDescription.defaultValue = attribute.defaultValue?.storedValue()
          entity.properties.append(attributeDescription)
        }

        // Establish the inheritance relation with the entities for immediate subclasses.
        entity.subentities = subtreeResults.map { $0.0.entityDescription }

        // Form the combined dictionary of EntityInfo for the given class and its subclasses.
        var combinedEntityInfoMap : [String: EntityInfo] = [objectInfo.name: .init(objectInfo, entity)]
        for subtreeResult in subtreeResults {
          try combinedEntityInfoMap.merge(subtreeResult.1) {
            throw Exception("\($0.name) and \($1.name) have the same name")
          }
        }

        return (EntityInfo(objectInfo, entity), combinedEntityInfoMap)
      }

  }
