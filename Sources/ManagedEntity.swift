/*

*/

import CoreData


public struct ManagedEntity
  {
    public let name : String
    public private(set) var attributes : [String: ManagedAttribute] = [:]
    public private(set) var relationships : [String: ManagedRelationship] = [:]
    public let entityDescription : NSEntityDescription
    public let managedObjectClass : ManagedObject.Type


    public init(objectType: ManagedObject.Type)
      {
        name = objectType.entityName
        managedObjectClass = objectType

        for (label, value) in objectType.instanceMirror.children {
          guard let label, label.hasPrefix("_") else { continue }
          guard let wrapper = value as? ManagedPropertyWrapper else { continue }
          let propertyName = label.removing(prefix: "_")
          switch wrapper.managedProperty {
            case let attribute as ManagedAttribute :
              attributes[propertyName] = attribute
            case let relationship as ManagedRelationship :
              relationships[propertyName] = relationship
            default :
              continue
          }
        }

        entityDescription = .init()
        entityDescription.name = objectType.entityName
        entityDescription.managedObjectClassName = objectType.entityName
      }
  }
