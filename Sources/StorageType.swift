/*

*/

import CoreData


public enum StorageType
  {
    case bool
    case data
    case date
    case double
    case float
    case int
    case int16
    case int32
    case int64
    case string

    public init?(swiftTypeName name: String)
      {
        switch name {
          case "Bool"   : self = .bool
          case "Data"   : self = .data
          case "Date"   : self = .date
          case "Double" : self = .double
          case "Float"  : self = .float
          case "Int"    : self = .int
          case "Int16"  : self = .int16
          case "Int32"  : self = .int32
          case "Int64"  : self = .int64
          case "String" : self = .string
          default :
            return nil
        }
      }

    public var swiftTypeName : String
      {
        switch self {
          case .bool : return "Bool"
          case .data : return "Data"
          case .date : return "Date"
          case .double : return "Double"
          case .float : return "Float"
          case .int : return "Int"
          case .int16 : return "Int16"
          case .int32 : return "Int32"
          case .int64 : return "Int64"
          case .string : return "String"
        }
      }

    public var coreDataAttributeType : NSAttributeDescription.AttributeType
      {
        switch self {
          case .bool   : return .boolean
          case .data   : return .binaryData
          case .date   : return .date
          case .double : return .double
          case .float  : return .float
          case .int    : return .integer64 // TODO: 32 on watchOS
          case .int16  : return .integer16
          case .int32  : return .integer32
          case .int64  : return .integer64
          case .string : return .string
        }
      }

    public func createNSObject(from json: Any) throws -> NSObject
      {
        switch self {
          case .bool   : return try NSNumber(value: throwingCast(json, as: Bool.self))
          case .data   : return try throwingCast(json, as: Data.self) as NSData
          case .date   : return try throwingCast(json, as: Date.self) as NSDate
          case .double : return try NSNumber(value: throwingCast(json, as: Double.self))
          case .float  : return try NSNumber(value: throwingCast(json, as: Float.self))
          case .int    : return try NSNumber(value: throwingCast(json, as: Int.self))
          case .int16  : return try NSNumber(value: throwingCast(json, as: Int16.self))
          case .int32  : return try NSNumber(value: throwingCast(json, as: Int32.self))
          case .int64  : return try NSNumber(value: throwingCast(json, as: Int64.self))
          case .string : return try throwingCast(json, as: String.self) as NSString
        }
      }
  }
