/*

*/


public typealias ObjectTypeSpec = Entity


public struct Entity
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
    public private(set) var attributes : [Attribute] = []
    public private(set) var relationships : [Relationship] = []
    public let identity : Identity


    public init(_ name: String, identity: Identity = .name, properties: [any Property] = [])
      {
        self.name = name
        self.attributes = properties.compactMap { $0 as? Attribute }
        self.relationships = properties.compactMap { $0 as? Relationship }
        self.identity = identity
      }


    public var properties : [any Property]
      { attributes + relationships }


    public var identityAttributeName : String?
      {
        guard case .name = identity else { return nil }
        return "name"
      }


    public var hasSingleInstance : Bool
      { identity == .singleton }
  }


extension Entity : TypeSpec
  {
    public init(name: String, json dict: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        self.name = name
        self.identity = try dict.requiredValue(for: "identity")

        if case .name = identity {
          attributes += [Attribute(name: "name", type: .native(.string))]
        }

        for (attname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "attributes") ?? [:] {
          attributes += [ try Attribute(name: attname, info: info, in: environment) ]
        }

        for (relname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "relationships") ?? [:] {
          relationships += [ try Relationship(name: relname, info: info) ]
        }
      }


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
