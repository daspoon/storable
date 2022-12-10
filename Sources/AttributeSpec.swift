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
    public let ingestKey : IngestKey

    /// The default value expressed as a Swift source string.
    public let defaultSwiftText : String?


    public init(name x: String, info: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        name = x

        type = try info.requiredValue(for: "type") { (v: Any) in
          guard let string = v as? String else { throw Exception("expecting string value for 'type'") }
          return try AttributeType(with: string, in: environment)
        }

        ingestKey = try .init(with: info["ingestKey"], for: name)

        defaultSwiftText = try info.optionalValue(for: "default")

        // Ensure the given string is a valid swift literal for the associated type
        try defaultSwiftText.map { text in
          let json = try JSONSerialization.jsonObject(with: text, encoding: .utf8, options: .fragmentsAllowed)
          try type.validate(json)
        }
      }


    public func generatePropertyDeclaration() -> String
      {
        "@\(type.swiftPropertyWrapper) var \(name) : \(type)"
      }


    public func generatePropertyDefinition() -> String?
      {
        "Attribute(\"\(name)\", \(type.isNative ? "nativeType" : "codableType"): \(type).self, ingestKey: .\(ingestKey), defaultValue: \(defaultSwiftText ?? "nil"))"
      }
  }
