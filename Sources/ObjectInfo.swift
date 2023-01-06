/*

*/

import CoreData


public struct ObjectInfo
  {
    public let name : String
    public private(set) var attributes : [String: AttributeInfo] = [:]
    public private(set) var relationships : [String: RelationshipInfo] = [:]
    public let entityDescription : NSEntityDescription
    public let managedObjectClass : Object.Type


    public init(objectType: Object.Type)
      {
        name = objectType.entityName
        managedObjectClass = objectType

        for (label, value) in objectType.instanceMirror.children {
          guard let label, label.hasPrefix("_") else { continue }
          guard let wrapper = value as? ManagedProperty else { continue }
          let propertyName = label.removing(prefix: "_")
          switch wrapper.propertyInfo {
            case let attribute as AttributeInfo :
              attributes[propertyName] = attribute
            case let relationship as RelationshipInfo :
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
