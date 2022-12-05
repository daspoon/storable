/*

*/

import CoreData


extension NSAttributeDescription
  {
    convenience init(name: String, type: AttributeType, isOptional: Bool)
      {
        self.init()
        self.name = name
        self.type = type
        self.isOptional = isOptional
      }
  }


extension NSAttributeDescription.AttributeType
  {
    init?(swiftTypeName name: String)
      {
        switch name {
          case "Bool"   : self = .boolean
          case "Date"   : self = .date
          case "Data"   : self = .binaryData
          case "Double" : self = .double
          case "Float"  : self = .float
          case "Int"    : self = .integer64
          case "Int16"  : self = .integer16
          case "Int32"  : self = .integer32
          case "Int64"  : self = .integer64
          case "String" : self = .string
          default :
            return nil
        }
      }

    var swiftTypeName : String?
      {
        switch self {
          case .boolean : return "Bool"
          case .binaryData : return "Data"
          case .date : return "Date"
          case .double : return "Double"
          case .float : return "Float"
          case .integer16 : return "Int16"
          case .integer32 : return "Int32"
          case .integer64 : return "Int64"
          case .string : return "String"
          default:
            return nil
        }
      }

    func ingest(json: Any) throws -> NSObject
      {
        switch self {
          case .boolean :
            return NSNumber(booleanLiteral: try throwingCast(json))
          case .binaryData :
            return try throwingCast(json, as: Data.self) as NSData
          case .date :
            return try throwingCast(json, as: Date.self) as NSDate
          case .double :
            return NSNumber(value: try throwingCast(json, as: Double.self))
          case .float :
            return NSNumber(value: try throwingCast(json, as: Float.self))
          case .integer16 :
            return NSNumber(value: try throwingCast(json, as: Int16.self))
          case .integer32 :
            return NSNumber(value: try throwingCast(json, as: Int32.self))
          case .integer64 :
            return NSNumber(value: try throwingCast(json, as: Int64.self))
          case .string :
            return try throwingCast(json, as: String.self) as NSString
          default :
            throw Exception("attribute storage type '\(self)' is not supported")
        }
      }
  }
