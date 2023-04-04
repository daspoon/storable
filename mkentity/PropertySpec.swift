/*

*/

import Storable
import StorableBase


enum PropertySpec : Ingestible
  {
    case attribute(type: String, defaultValue: String?)
    case relationship(type: String, inverse: String, deleteRule: String)

    init(json: [String: Any]) throws
      {
        switch try json.requiredValue(of: String.self, for: "kind") {
          case "attribute" :
            self = .attribute(
              type: try json.requiredValue(of: String.self, for: "type"),
              defaultValue: try json.optionalValue(of: String.self, for: "defaultValue")
            )
          case "relationship" :
            self = .relationship(
              type: try json.requiredValue(for: "type"),
              inverse: try json.requiredValue(for: "inverse"),
              deleteRule: try json.requiredValue(for: "deleteRule")
            )
          case let whatever :
            throw Exception("invalid property kind: \(whatever)")
        }
      }

    func textForDescriptor(with name: String) -> String
      {
        switch self {
          case .attribute(let type, let defaultValue) :
            return ".attribute(.init(name: \"\(name)\", type: \(type).self, defaultValue: \(defaultValue ?? "nil")))"
          case .relationship(let type, let inverse, let deleteRule) :
            return ".relationship(.init(name: \"\(name)\", type: \(type).self, inverse: \"\(inverse)\", deleteRule: .\(deleteRule)))"
        }
      }

    func textArrayForDeclaration(with name: String) -> [String]
      {
        switch self {
          case .attribute(let type, _) :
            return [
              "public var \(name) : \(type) {",
              "  get { attributeValue(forKey: \"\(name)\") }",
              "  set { setAttributeValue(newValue, forKey: \"\(name)\") }",
              "}",
            ]
          case .relationship(let type, _, _) :
            return [
              "public var \(name) : \(type) {",
              "  get { value(forKey: \"\(name)\") as! \(type) }",
              "  set { setValue(newValue, forKey: \"\(name)\") }",
              "}",
            ]
        }
      }
  }