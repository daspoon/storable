/*

*/

import CoreData


public final class Entity
  {
    public let name : String
    public let properties : [String: Property]
    public let entityDescription : NSEntityDescription
    public let managedObjectClass : Object.Type


    public init(objectType: Object.Type)
      {
        name = objectType.entityName
        managedObjectClass = objectType
        properties = Dictionary(uniqueKeysWithValues: objectType.properties)

        // Create a partial entity description containing the declared attributes; relationships are processed later by the enclosing Schema.
        entityDescription = .init()
        entityDescription.name = name
        entityDescription.managedObjectClassName = name
        for (name, property) in properties {
          guard let attribute = property as? Attribute else { continue }
          let attributeDescription = NSAttributeDescription()
          attributeDescription.name = name
          attributeDescription.type = attribute.coreDataAttributeType
          attributeDescription.isOptional = attribute.allowsNilValue
          entityDescription.properties.append(attributeDescription)
        }
      }


    public var hasSingleInstance : Bool
      { managedObjectClass.identity == .singleton }
  }
