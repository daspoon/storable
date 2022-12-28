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
        entityDescription = .init()
        entityDescription.name = objectType.entityName
        entityDescription.managedObjectClassName = objectType.entityName
      }


    public var hasSingleInstance : Bool
      { managedObjectClass.identity == .singleton }
  }
