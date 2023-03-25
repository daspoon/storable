/*

  Created by David Spooner

*/

import CoreData


/// A Schema corresponds to an NSManagedObjectModel, but is generated from a list of ManagedObject subclasses and maintains additional information about those classes.

public struct Schema
  {
    /// A convenience type pairing the data structures generated on demand: the managed object model and the mapping of entity names to ClassInfo structures.
    public typealias RuntimeInfo = (managedObjectModel: NSManagedObjectModel, classInfoByName: [String: ClassInfo])


    /// The ManagedObject classes given on initialization, organized as a tree closed under inheritance.
    private var classTree : ClassTree<ManagedObject> = .init()

    /// Map the names of defined entities to Entity instances.
    public private(set) var entityInfoByName : [String: Entity] = [:]


    /// Create a new instance with a given list of ManagedObject subclasses and an optional model version identifier.
    public init(objectTypes: [ManagedObject.Type]) throws
      {
        for objectType in objectTypes {
          try self.addObjectType(objectType)
        }
      }


    /// Associate a new object type to a new instance of Entity.
    private mutating func addObjectType(_ givenType: ManagedObject.Type, entityInfo givenInfo: Entity? = nil) throws
      {
        precondition(entityInfoByName[givenType.entityName] == nil && givenInfo.map({$0.managedObjectClass == givenType}) != .some(false), "invalid argument")

        try classTree.add(givenType) { newType in
          let entityName = newType.entityName
          let existingInfo = entityInfoByName[entityName]
          guard existingInfo == nil else { throw Exception("entity name \(entityName) is defined by both \(existingInfo!.managedObjectClass) and \(newType)") }
          entityInfoByName[entityName] = try Entity(objectType: newType)
        }
      }


    /// Create the pairing of managed object model and entity mapping implied by the schema. The given versionId must be the one maintained by the instance unless none was given on initialization.
    public func createRuntimeInfo() throws -> RuntimeInfo
      {
        // Perform a post-order traversal of the class hierarchy to create an entity description for each class, establish inheritance between entities, and populate classInfoByName...
        var classInfoByName : [String: ClassInfo] = [:]
        _ = classTree.fold { (objectType: ManagedObject.Type, subentities: [NSEntityDescription]) -> NSEntityDescription in
          // Ignore the root class (i.e. ManagedObject) which is not modeled.
          guard objectType != ManagedObject.self else { return .init() }
          // Get the corresponding Entity
          guard let entityInfo = entityInfoByName[objectType.entityName] else { fatalError() }
          // Create an NSEntityDescription
          let entityDescription = NSEntityDescription()
          entityDescription.name = entityInfo.name
          entityDescription.managedObjectClassName = NSStringFromClass(objectType)
          entityDescription.isAbstract = objectType.isAbstract
          entityDescription.subentities = subentities
          // Add a registry entry
          classInfoByName[entityInfo.name] = ClassInfo(entityInfo, entityDescription)
          // Return the generated entity
          return entityDescription
        }

        // Extend each NSEntityDescription with the specified attributes.
        for (_, classInfo) in classInfoByName {
          for (name, attribute) in classInfo.attributes {
            let attributeDescription = NSAttributeDescription()
            attributeDescription.name = name
            attributeDescription.type = attribute.attributeType
            attributeDescription.isOptional = attribute.isOptional
            attributeDescription.valueTransformerName = attribute.valueTransformerName?.rawValue
            attributeDescription.defaultValue = attribute.defaultValue?.storedValue()
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

        return (objectModel, classInfoByName)
      }
  }
