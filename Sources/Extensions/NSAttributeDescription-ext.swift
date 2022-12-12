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
    public func createNSObject(from json: Any) throws -> NSObject
      {
        switch self {
          case .boolean   : return try NSNumber(value: throwingCast(json, as: Bool.self))
          case .binaryData   : return try throwingCast(json, as: Data.self) as NSData
          case .date   : return try throwingCast(json, as: Date.self) as NSDate
          case .double : return try NSNumber(value: throwingCast(json, as: Double.self))
          case .float  : return try NSNumber(value: throwingCast(json, as: Float.self))
          case .integer16  : return try NSNumber(value: throwingCast(json, as: Int.self))
          case .integer32  : return try NSNumber(value: throwingCast(json, as: Int.self))
          case .integer64  : return try NSNumber(value: throwingCast(json, as: Int.self))
          case .string : return try throwingCast(json, as: String.self) as NSString
          default :
            throw Exception("unsupported attribute type")
        }
      }
  }
