/*

*/

import Foundation


public struct AttributeSpec : PropertySpec
  {
    /// The managed property name.
    public let name : String

    /// A descriptor for the type of attribute values.
    public let type : AttributeType

    /// The key used to extract the property value from the ingest data provided on object initialization.
    public let ingestKey : IngestKey?

    /// The default value expressed as a Swift source string.
    public private(set) var defaultValue : (any Defaultable)?

    /// An optional transform applied to the input.
    public let transform : (any IngestTransform)?


    public init(name x: String, info: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        name = x

        type = try info.requiredValue(for: "type") { (v: Any) in
          guard let string = v as? String else { throw Exception("expecting string value for 'type'") }
          return try AttributeType(with: string, in: environment)
        }

        ingestKey = try info["ingestKey"].map { try IngestKey(with: $0, for: x) }

        transform = try info.optionalValue(of: String.self, for: "transform").map { try ingestTransform(named: $0) }

        // Ensure the default value, if given, is of the expected type.
        defaultValue = try info["default"].map {
          let v : Any
          if let transform {
            v = try transform.validate($0)
          }
          else {
            v = try type.validate($0)
          }
          guard let value = v as? any Defaultable else { throw Exception("\(v) cannot be used as a default value") }
          return value
        }
      }


    public func codegenPropertyDeclaration() -> String
      {
        "@\(type.swiftPropertyWrapper) var \(name) : \(type)"
      }


    public func codegenPropertyValue() -> String?
      {
        return codegenConstructor("Attribute", argumentPairs: [
          (nil, "\"" + name + "\""),
          (type.isNative ? "nativeType" : "codableType", type.description + ".self"),
          ingestKey.map { ("ingestKey", ".\($0)") },
          transform.map { ("transform", $0.description) },
          defaultValue.map { ("defaultValue", $0.asSwiftLiteral) },
        ])
      }
  }
