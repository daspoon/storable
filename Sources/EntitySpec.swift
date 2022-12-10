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

        for (attname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "attributes") ?? [:] {
          try addPropertySpec(try AttributeSpec(name: attname, info: info, in: environment))
        }

        for (relname, info) in try dict.optionalValue(of: [String: [String: Any]].self, for: "relationships") ?? [:] {
          try addPropertySpec(try RelationshipSpec(name: relname, info: info))
        }

        // Ensure a name attribute is defined if necessary.
        if case .name = identity {
          guard let nameAttr = properties["name"] as? AttributeSpec, case .native(.string) = nameAttr.type else { throw Exception("string-valued 'name' attribute is required") }
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
          \(properties.values.compactMap({$0.generatePropertyDefinition()}).joined(separator: ",\n"))
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
      { ["Race", "Demon", "Skill", "SkillGrant", "RaceFusion", "State"].contains(name) ? name + "Model" : nil }
  }
