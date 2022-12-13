/*

*/

import CoreData


/// Represents a Swift type which is supported for managed object attributes.
public indirect enum AttributeType : CustomStringConvertible
  {
    /// Native types supported by CoreData
    case native(StorageType)

    /// Custom value types defined by the configuration.
    case customEnum(EnumerationSpec)

    /// An optional supported type.
    case optional(Self)

    /// Homogeneous arrays of supported types.
    case array(Self)

    /// Homogeneous dictionaries mapping strings to supported types.
    case dictionary(Self)


    /// Parse an instance from a string.
    public init(with string: String, in environment: [String: any TypeSpec]) throws
      {
        let scanner = Scanner(string: string)
        self = try Self.parseType(scanner, in: environment)
        guard scanner.isAtEnd else { fatalError("unexpected trailing characters") }
      }


    public func validate(_ json: Any) throws -> Any
      {
        switch self {
          case .native(let storageType) :
            return try storageType.validate(json)
          case .customEnum(let enumSpec) :
            return try enumSpec.validate(json)
          case .optional(let wrapperType) :
            return try wrapperType.validate(json)
          case .array(let elementType) :
            return try throwingCast(json, as: [Any].self).map { try elementType.validate($0) }
          case .dictionary(let valueType) :
            return Dictionary(uniqueKeysWithValues: try throwingCast(json, as: [String: Any].self).map {($0, try valueType.validate($1))})
        }
      }


    /// Parse an type element from the given scanner.
    private static func parseType(_ scanner: Scanner, in environment: [String: any TypeSpec]) throws -> Self
      {
        var resultingType : Self

        if let name = scanner.scanIdentifier() {
          if let storageType = StorageType(swiftTypeName: name) {
            resultingType = .native(storageType)
          }
          else if let referencedType = environment[name] {
            guard let customType = referencedType as? EnumerationSpec else { throw Exception("unsupported custom attribute type '\(name)'") }
            resultingType = .customEnum(customType)
          }
          else {
            throw Exception("unknown type identifier '\(name)'")
          }
        }
        else if scanner.scanString("[") != nil {
          resultingType = try parseType(scanner, in: environment)
          switch scanner.scanString(":") {
            case .none :
              resultingType = .array(resultingType)
            case .some :
              guard case .native(.string) = resultingType else { throw Exception("dictionary key type must be 'String'") }
              resultingType = .dictionary(try parseType(scanner, in: environment))
          }
          guard scanner.scanString("]") != nil else { throw Exception("expected closing ']'") }
        }
        else {
          throw Exception("expecting type name or '['")
        }

        if scanner.scanString("?") != nil {
          resultingType = .optional(resultingType)
        }

        return resultingType
      }


    /// Return the corresponding Swift type expression as a string.
    public var description : String
      {
        switch self {
          case .native(let code) :
            return code.swiftTypeName
          case .customEnum(let enumType) :
            return enumType.name
          case .optional(let type) :
            return type.description + "?"
          case .array(let elementType) :
            return "[" + elementType.description + "]"
          case .dictionary(let elementType) :
            return "[String: " + elementType.description + "]"
        }
      }


    /// Return true if the type is supported directly by CoreData.
    public var isNative : Bool
      {
        guard case .native = self else { return false }
        return true
      }


    /// The name of the property wrapper used in Swift property declarations.
    public func swiftPropertyWrapper(for propertyName: String) -> String
      {
        switch self {
          case .native : return "NSManaged"
          default :
            return "Persistent(\"" + propertyName + "\")"
        }
      }
  }
