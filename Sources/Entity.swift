/*

*/

import CoreData


public final class Entity
  {
    public let name : String
    public let identity : Identity
    public private(set) var properties : [String: Property] = [:]
    public let entityDescription : NSEntityDescription
    public let managedObjectClass : Object.Type


    public init(_ objectType: Object.Type, identity: Identity, properties: [Property] = [])
      {
        self.name = "\(objectType)"
        self.identity = identity
        self.properties = Dictionary(uniqueKeysWithValues: properties.map {($0.name, $0)})
        self.entityDescription = .init()
        self.managedObjectClass = objectType
      }


    public var attributes : [Attribute]
      { properties.values.compactMap { $0 as? Attribute } }


    public var relationships : [Relationship]
      { properties.values.compactMap { $0 as? Relationship } }


    public var hasSingleInstance : Bool
      { identity == .singleton }
  }
