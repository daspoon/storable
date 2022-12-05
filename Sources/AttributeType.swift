/*

*/

import CoreData


/// Represents a Swift type which is supported for managed object attributes.
public indirect enum AttributeType
  {
    /// Native types supported by CoreData
    case native(StorageType)

    /// Custom value types defined by the configuration.
    case customEnum(EnumTypeSpec)

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


    /// Parse an type element from the given scanner.
    private static func parseType(_ scanner: Scanner, in environment: [String: any TypeSpec]) throws -> Self
      {
        var resultingType : Self

        if let name = scanner.scanIdentifier() {
          if let storageType = StorageType(swiftTypeName: name) {
            resultingType = .native(storageType)
          }
          else if let referencedType = environment[name] {
            guard let customType = referencedType as? EnumTypeSpec else { throw Exception("unsupported custom attribute type '\(name)'") }
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
    public var swiftTypeExpression : String
      {
        switch self {
          case .native(let code) :
            return code.swiftTypeName
          case .customEnum(let enumType) :
            return enumType.name
          case .optional(let type) :
            return type.swiftTypeExpression + "?"
          case .array(let elementType) :
            return "[" + elementType.swiftTypeExpression + "]"
          case .dictionary(let elementType) :
            return "[String: " + elementType.swiftTypeExpression + "]"
        }
      }


    /// The name of the property wrapper used in Swift property declarations.
    public var swiftPropertyWrapper : String
      {
        switch self {
          case .native : return "NSManaged"
          default :
            return "Persistent"
        }
      }
  }
