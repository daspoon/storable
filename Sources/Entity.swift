/*

*/


public final class Entity
  {
    public let name : String
    public let identity : Identity
    public private(set) var properties : [String: Property] = [:]


    public init(_ name: String, identity: Identity = .name, properties: [Property] = [])
      {
        self.name = name
        self.identity = identity
        self.properties = Dictionary(uniqueKeysWithValues: properties.map {($0.name, $0)})
      }


    public var attributes : [Attribute]
      { properties.values.compactMap { $0 as? Attribute } }


    public var relationships : [Relationship]
      { properties.values.compactMap { $0 as? Relationship } }


    public var identityAttributeName : String?
      {
        guard case .name = identity else { return nil }
        return "name"
      }


    public var hasSingleInstance : Bool
      { identity == .singleton }


  }
