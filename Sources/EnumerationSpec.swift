/*

*/

/// EnumerationSpec corresponds to the JSON specification of a generated Swift enum conforming to the Enumeration protocol.
///
public struct EnumerationSpec : TypeSpec
  {
    /// The data required to synthesize an enum value, specified as a JSON dictionary.
    public struct Value : Ingestible
      {
        /// The 'name' element of the input dictionary. Required.
        public let name : String
        /// The 'ingestName' is the string used to identify enum values when ingestring object properties of the enum type. The default is the given name.
        public let ingestName : String?
        /// The 'shortName' is the string used to identity associated values in compact UI scenarios. The default is the given name.
        public let shortName : String?
        /// Together the following specify the icon used to identity cases in compact UI scenarios. The default is an image of the associated name in the application bundle.
        public let iconName : String?
        public let iconColor : Color?
        public let iconSource : IconSpec.Source?

        public init(json dict: [String: Any]) throws
          {
            name = try dict.requiredValue(for: "name")
            ingestName = try dict.optionalValue(for: "ingestName") ?? name
            shortName = try dict.optionalValue(for: "shortName")
            iconName = try dict.optionalValue(for: "iconName")
            iconColor = try dict.optionalValue(for: "iconColor")
            iconSource = try dict.optionalValue(for: "iconSource")
          }

        public var hasIconSpec : Bool
          { iconName != nil || iconColor != nil || iconSource != nil }

        public var iconSpec : IconSpec
          { .init(name: iconName ?? name, source: iconSource, color: iconColor) }
      }

    public let name : String
    public let rawTypeName : String
    public let baseEnumTypes : [EnumerationSpec]
    public let definedValues : [Value]
    public let definedValuesByName : [String: Value]


    public init(name n: String, json dict: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        name = n
        definedValues = try dict.requiredArrayValue(of: Value.self, for: "values")

        rawTypeName = try dict.optionalValue(for: "representation") ?? "Int"
        guard ["Int", "String"].contains(rawTypeName) else { throw Exception("representation must be either Int or String") }

        if let baseName = try dict.optionalValue(of: String.self, for: "extends") {
          guard let baseType = environment[baseName] else { throw Exception("unknown base type '\(baseName)'") }
          guard let baseEnumType = baseType as? EnumerationSpec else { throw Exception("invalid base type '\(baseName)'") }
          baseEnumTypes = baseEnumType.baseEnumTypes + [baseEnumType]
        }
        else {
          baseEnumTypes = []
        }

        let allDefinedValues = ((baseEnumTypes.flatMap {$0.definedValues}) + definedValues).map { ($0.name, $0) }
        definedValuesByName = try Dictionary(allDefinedValues, uniquingKeysWith: { v1, v2 in
          throw Exception("multiple definitions of '\(v1.name)'")
        })
      }


    public var values : [Value]
      { baseEnumTypes.flatMap({$0.definedValues}) + definedValues }


    public func validate(_ json: Any) throws -> Any
      {
        let string = try throwingCast(json, as: String.self)
        guard definedValuesByName[string] != nil else {
          throw Exception("'\(string) does not name a member of enum \(name)")
        }
        return string
      }


    public func codegenTypeDefinition(for modelName: String) -> String
      {
        """
        public enum \(name) : \(rawTypeName), Enumeration
          {
            \(values.map({"case \($0.name)"}).joined(separator: .newline() + .space(4)))

            public init(json: String) throws {
              switch json {
                \(values.map({"case \"\($0.ingestName ?? $0.name)\" : self = .\($0.name)"}).joined(separator: .newline() + .space(8)))
                default :
                  throw Exception("invalid value for \\(Self.self)")
              }
            }

            public var name : String {
              switch self {
                \(values.map({"case .\($0.name) : return \"\($0.name)\""}).joined(separator: .newline() + .space(8)))
              }
            }

        """ + (values.allSatisfy({$0.shortName == nil}) ? "" :
        """

            public var shortName : String {
              switch self {
                \(values.map({"case .\($0.name) : return \"\($0.shortName ?? $0.name)\""}).joined(separator: .newline() + .space(8)))
              }
            }

        """) + (values.allSatisfy({$0.hasIconSpec == false}) ? "" :
        """

            public var iconSpec : IconSpec {
              switch self {
                \(values.map({"case .\($0.name) : return \($0.iconSpec.swiftText)"}).joined(separator: .newline() + .space(8)))
              }
            }

        """) +
        """
        }
        """.compressingVerticalWhitespace()
      }
  }
