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
        /// The 'intValue' element of the input dictionary which determines the associated rawValue. The default is nil, which means rawValue is determined by definition order.
        public let intValue : Int?
        /// The 'ingestName' is the string used to identify enum values when ingestring object properties of the enum type. The default is the given name.
        public let ingestName : String
        /// The 'shortName' is the string used to identity associated values in compact UI scenarios. The default is the given name.
        public let shortName : String
        /// The 'iconName' is the name of the icon used to identity associated values in compact UI scenarios. The default is the given name.
        public let iconName : String

        public init(json dict: [String: Any]) throws
          {
            name = try dict.requiredValue(for: "name")
            intValue = try dict.optionalValue(of: Int.self, for: "intValue")
            ingestName = try dict.optionalValue(for: "ingestName") ?? name
            shortName = try dict.optionalValue(for: "shortName") ?? name
            iconName = try dict.optionalValue(for: "iconName") ?? name
          }
      }

    public let name : String
    public let baseEnumTypes : [EnumerationSpec]
    public let definedValues : [Value]

    public init(name n: String, json dict: [String: Any], in environment: [String: any TypeSpec]) throws
      {
        name = n
        definedValues = try dict.requiredArrayValue(of: Value.self, for: "values")

        if let baseName = try dict.optionalValue(of: String.self, for: "extends") {
          guard let baseType = environment[baseName] else { throw Exception("unknown base type '\(baseName)'") }
          guard let baseEnumType = baseType as? EnumerationSpec else { throw Exception("invalid base type '\(baseName)'") }
          baseEnumTypes = baseEnumType.baseEnumTypes + [baseEnumType]
        }
        else {
          baseEnumTypes = []
        }

        let duplicates = Set(baseEnumTypes.flatMap({$0.definedValues.map({$0.name})})).intersection(definedValues.map({$0.name}))
        guard duplicates.isEmpty else {
          throw Exception("cases \(duplicates.map({"'\($0)'"}).joined(separator: ", ")) already defined by base type")
        }
      }


    public var values : [Value]
      { baseEnumTypes.flatMap({$0.definedValues}) + definedValues }


    public func generateTypeDefinition(for modelName: String) -> String
      {
        """
        public enum \(name) : Int, Enumeration {
          \(values.map({"case \($0.name) \($0.intValue.map({" = \($0)"}) ?? "")"}).joined(separator: "\n" + .space(2)))

          public init(json: String) throws {
            switch json {
              \(values.map({"case \"\($0.ingestName)\" : self = .\($0.name)"}).joined(separator: "\n" + .space(6)))
              default :
                throw Exception("invalid value for \\(Self.self)")
            }
          }

          public var name : String {
            switch self {
              \(values.map({"case .\($0.name) : return \"\($0.name)\""}).joined(separator: "\n" + .space(6)))
            }
          }

          \(baseEnumTypes.map({
          "var \($0.name.camelCased) : \($0.name)? { .init(rawValue: rawValue) }"
          }).joined(separator: "\n" + .space(2)))
        }
        """
      }
  }
