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


    public func codegenEntityValue() -> String
      {
        return { properties in
          """
          Entity(\(name).self, identity: .\(identity), properties: [
            \(properties.compactMap({$0.codegenPropertyValue()}).joined(separator: "," + .newline()).indented(2))
          ])
          """
        }(properties.values.sorted(by: {$0.name < $1.name}))
      }


    public func codegenTypeDefinition(for modelName: String) -> String
      {
        return { requiredProtocolName, properties in
          """
          @objc(\(name))
          public class \(name) : Object\(requiredProtocolName.map {", " + $0} ?? "")
            {
              typealias Game = \(modelName)
              \(properties.map({$0.codegenPropertyDeclaration()}).joined(separator: .newline()).indented(4))
            }
          """
        }(
          ["Race", "Demon", "Skill", "SkillGrant", "RaceFusion", "State"].contains(name) ? name + "Model" : nil,
          properties.values.sorted(by: {$0.name < $1.name})
        )
      }
  }
