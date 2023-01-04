/*

*/

import CoreData


public struct ManagedEntity
  {
    public let name : String
    public let properties : [String: ManagedProperty]
    public let entityDescription : NSEntityDescription
    public let managedObjectClass : ManagedObject.Type


    public init(objectType: ManagedObject.Type)
      {
        name = objectType.entityName
        managedObjectClass = objectType

        properties = Dictionary(uniqueKeysWithValues: objectType.instanceMirror.children.compactMap { label, value in
          guard let wrapper = value as? ManagedPropertyWrapper else { return nil }
          guard let label, label.hasPrefix("_") else { return nil }
          return (label.removing(prefix: "_"), wrapper.managedProperty)
        })

        entityDescription = .init()
        entityDescription.name = objectType.entityName
        entityDescription.managedObjectClassName = objectType.entityName
      }
  }
