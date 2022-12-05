/*

*/


/// Represents a managed object attribute.
public struct Attribute : Property
  {
    /// The managed property name.
    public let name : String

    /// A descriptor for the type of attribute values.
    public let type : AttributeType

    /// The key used to extract the property value from the ingest data provided on object initialization.
    public let ingestKey : IngestKey


    public init(name x: String, type t: AttributeType, ingestKey k: IngestKey? = nil)
      {
        name = x
        type = t
        ingestKey = k ?? .element(x)
      }


    public init(name x: String, info: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        name = x

        type = try info.requiredValue(for: "type") { (v: Any) in
          guard let string = v as? String else { throw Exception("expecting string value for 'type'") }
          return try AttributeType(with: string, in: environment)
        }

        ingestKey = try info.optionalValue(for: "ingestKey") ?? .element(name)
      }


    public var optional : Bool
      {
        guard case .optional = type else { return false }
        return true
      }


    public var swiftText : String
      {
        "@\(type.swiftPropertyWrapper) var \(name) : \(type.swiftTypeExpression)"
      }
  }
