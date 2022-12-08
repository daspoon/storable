/*

*/

import CoreData


public struct Schema
  {
    public let name : String
    public let configurationEntityName : String
    public let entitiesByName : [String: Entity]

    private var managedObjectModel : NSManagedObjectModel!


    public init(name: String, configurationEntityName configName: String = "Configuration", entities: [Entity])
      {
        self.name = name
        self.configurationEntityName = configName
        self.entitiesByName = Dictionary(uniqueKeysWithValues: entities.map {($0.name, $0)})
      }


    /// Return the associated NSManagedObjectModel, creating it if necessary.
    public func createManagedObjectModel() throws -> NSManagedObjectModel
      {
        guard managedObjectModel == nil else { return managedObjectModel! }

        let managedObjectModel = NSManagedObjectModel()

        // Map each model name to a pairing of a partial NSEntityDescription and a list of relationships to be processed later.
        let entityInfo : [String: (entityDescription: NSEntityDescription, relationships: [Relationship])] = Dictionary(uniqueKeysWithValues: entitiesByName.map { (name, entity) in
          let entityDescription = entity.entityDescription
          entityDescription.name = name
          entityDescription.managedObjectClassName = NSStringFromClass(entity.managedObjectClass)
          // Initialize the entity's attributes
          entityDescription.properties = entity.attributes.map { attribute in
            NSAttributeDescription(name: attribute.name, type: attribute.coreDataStorageType, isOptional: attribute.optional)
          }
          // Conditionally add a string-valued attribute for the object identifier.
          if let identityName = entity.identityAttributeName {
            entityDescription.properties.append(NSAttributeDescription(name: identityName, type: .string, isOptional: false))
          }
          return (entity.name, (entityDescription, entity.relationships))
        })

        // Ensure the configuration entity is defined and as has a single instance.
        guard let configurationEntity = entitiesByName[configurationEntityName] else { throw Exception("Entity '\(configurationEntityName)' is not defined") }
        guard configurationEntity.hasSingleInstance else { throw Exception("Entity '\(configurationEntityName)' must have a single instance") }

        // Now add each specified relationship and its inverse to the corresponding entity descriptions.
        for (entityName, info) in entityInfo {
          for relationship in info.relationships {
            // Ensure the destination entity is defined
            guard let relatedEntityDescription = entityInfo[relationship.relatedEntityName]?.0 else {
              throw Exception("unknown target entity \(relationship.relatedEntityName) for relationship '\(relationship.name)' of \(entityName)")
            }
            // Ensure the specified inverse is not already defined
            guard relatedEntityDescription.relationshipsByName[relationship.inverseName] == nil else {
              throw Exception("inverse '\(relationship.inverseName)' for relationship '\(relationship.name)' of \(entityName) already defined on \(relationship.relatedEntityName)")
            }
            // Define the CoreData relationship and its inverse
            let (forwardDescription, inverseDescription) = (NSRelationshipDescription(), NSRelationshipDescription())
            forwardDescription.name = relationship.name
            forwardDescription.destinationEntity = relatedEntityDescription
            forwardDescription.inverseRelationship = inverseDescription
            forwardDescription.rangeOfCount = relationship.arity.rangeOfCount
            inverseDescription.name = relationship.inverseName
            inverseDescription.destinationEntity = info.entityDescription
            inverseDescription.inverseRelationship = forwardDescription
            inverseDescription.rangeOfCount = relationship.inverseArity.rangeOfCount
            // Add the relationship and its inverse to the corresponding CoreData entities
            info.entityDescription.properties.append(forwardDescription)
            relatedEntityDescription.properties.append(inverseDescription)
          }
        }

        // Add the generated entities to the CoreData model
        managedObjectModel.entities = entityInfo.values.map { $0.entityDescription }

        return managedObjectModel
      }
  }
