/*

*/

import CoreData


/// ObjectInfo is conceptually equivalent to NSEntityDescription, but maintains additional data required to perform object ingestion.

public struct ObjectInfo
  {
    public let name : String
    public private(set) var attributes : [String: AttributeInfo] = [:]
    public private(set) var relationships : [String: RelationshipInfo] = [:]
    public private(set) var fetchedProperties : [String: FetchedPropertyInfo] = [:]
    public let managedObjectClass : Object.Type


    /// Create a new instance for the given subclass of Object.
    public init(objectType: Object.Type) throws
      {
        name = objectType.entityName
        managedObjectClass = objectType

        // Skip the base class Object since it has no properties, and attempting to create a mirror crashes...
        guard objectType != Object.self else { return }

        for (label, value) in objectType.instanceMirror.children {
          guard let label, label.hasPrefix("_") else { continue }
          guard let info = (value as? ManagedProperty)?.propertyInfo else { continue }
          let propertyName = label.removing(prefix: "_")
          guard info.name == propertyName else {
            throw Exception("declared property name must match wrapper argument")
          }
          switch info {
            case let attribute as AttributeInfo :
              attributes[propertyName] = attribute
            case let relationship as RelationshipInfo :
              relationships[propertyName] = relationship
            case let fetchedProperty as FetchedPropertyInfo :
              fetchedProperties[propertyName] = fetchedProperty
            default :
              log("unsupported PropertyInfo type: \(type(of: info))")
          }
        }
      }
  }
