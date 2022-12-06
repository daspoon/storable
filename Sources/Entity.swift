/*

*/


public typealias ObjectTypeSpec = Entity


public final class Entity : TypeSpec
  {
    /// The notion of instance identity
    public enum Identity : String, Ingestible {
      /// There is no inherent identity.
      case anonymous
      /// Identity is given by the string value of the 'name' attribute.
      case name
      /// There is a single instance of the entity.
      case singleton
    }

    public let name : String
    public let identity : Identity
    public private(set) var properties : [String: Property] = [:]


    public init(_ name: String, identity: Identity = .name, properties: [Property] = [])
      {
        self.name = name
        self.identity = identity
        self.properties = Dictionary(uniqueKeysWithValues: properties.map {($0.name, $0)})
      }


    /// Create an entity from a JSON type specification.
    public init(name: String, json dict: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        self.name = name
        self.identity = try dict.requiredValue(for: "identity")

        if case .name = identity {
          try addProperty(Attribute(name: "name", type: .native(.string)))
        }

        for (attname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "attributes") ?? [:] {
          try addProperty(try Attribute(name: attname, info: info, in: environment))
        }

        for (relname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "relationships") ?? [:] {
          try addProperty(try Relationship(name: relname, info: info))
        }
      }


    public var attributes : [Attribute]
      { properties.values.compactMap { $0 as? Attribute } }


    public var relationships : [Relationship]
      { properties.values.compactMap { $0 as? Relationship } }


    func addProperty(_ property: Property) throws
      {
        guard properties[property.name] == nil else { throw Exception("multiple definitions for property '\(property.name)'") }

        properties[property.name] = property
      }


    func addInverse(of relationship: Relationship, on other: Entity) throws
      {
        try addProperty(Relationship(
          name: relationship.inverseName,
          arity: relationship.inverseArity,
          ingestKey: .none,
          ingestMode: .reference,
          deleteRule: relationship.inverseDeleteRule,
          relatedEntityName: other.name,
          inverseName: relationship.name,
          inverseArity: relationship.arity,
          inverseDeleteRule: relationship.deleteRule
        ))
      }


    public var identityAttributeName : String?
      {
        guard case .name = identity else { return nil }
        return "name"
      }


    public var hasSingleInstance : Bool
      { identity == .singleton }


    public func generateSwiftText(for modelName: String) -> String
      {
        """
        public class \(name) : Object\(requiredProtocolName.map {", " + $0} ?? "")
        {
          typealias Game = \(modelName)
          \(attributes.map({$0.generateSwiftText(for: modelName)}).joined(separator: "\n" + .space(2)))
          \(relationships.map({$0.generateSwiftText(for: modelName)}).joined(separator: "\n" + .space(2)))
        }
        """
      }


    var requiredProtocolName : String?
      { ["Race", "Demon", "Skill", "SkillGrant", "RaceFusion"].contains(name) ? name + "Model" : nil }
  }
