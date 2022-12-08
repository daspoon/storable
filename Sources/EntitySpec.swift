/*

*/

import Foundation


public final class EntitySpec : TypeSpec
  {
    public let name : String
    public let identity : Identity
    public private(set) var properties : [String: PropertySpec] = [:]


    /// Create an entity from a JSON type specification.
    public init(name: String, json dict: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        self.name = name

        self.identity = try dict.requiredValue(of: Identity.self, for: "identity")

        if case .name = identity {
          try addPropertySpec(AttributeSpec(name: "name", info: ["name": "name", "type": "String"], in: environment))
        }

        for (attname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "attributes") ?? [:] {
          try addPropertySpec(try AttributeSpec(name: attname, info: info, in: environment))
        }

        for (relname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "relationships") ?? [:] {
          try addPropertySpec(try RelationshipSpec(name: relname, info: info))
        }
      }


    func addPropertySpec(_ property: PropertySpec) throws
      {
        guard properties[property.name] == nil else { throw Exception("multiple definitions for property '\(property.name)'") }

        properties[property.name] = property
      }


    public func generateEntityDefinition() -> String
      {
        """
        Entity(\(name).self, identity: .\(identity), properties: [
          \(properties.values.map({$0.generatePropertyDefinition()}).joined(separator: ",\n"))
        ])
        """
      }


    public func generateClassDefinition(for modelName: String) -> String
      {
        """
        @objc(\(name))
        public class \(name) : Object\(requiredProtocolName.map {", " + $0} ?? "")
        {
          typealias Game = \(modelName)
          \(properties.map({$1.generatePropertyDeclaration()}).joined(separator: "\n" + .space(2)))
        }
        """
      }


    var requiredProtocolName : String?
      { ["Race", "Demon", "Skill", "SkillGrant", "RaceFusion"].contains(name) ? name + "Model" : nil }
  }
