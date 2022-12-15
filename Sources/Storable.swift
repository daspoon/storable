/*

*/

import CoreData


public protocol Storable
  {
    associatedtype StoredType : Storage

    static var attributeType : NSAttributeDescription.AttributeType { get }

    func storedValue() throws -> StoredType

    static func decodeStoredValue(_ storedValue: StoredType) throws -> Self

    static var isOptional : Bool { get }

    static var nullValue : Self { get }

    var isNullValue : Bool { get }
  }


extension Storable
  {
    public static var isOptional : Bool
      { false }

    public static var nullValue : Self
      { fatalError("required when isOptional returns true") }

    public var isNullValue : Bool
      { false }
  }



// MARK: - CoreData attribute types supported by  are Storable -

extension Bool : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .boolean }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.boolValue }
  }


extension Data : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .binaryData }
    public func storedValue() throws -> NSData
      { self as NSData }
    public static func decodeStoredValue(_ object: NSData) throws -> Self
      { object as Data }
  }


extension Date : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .date }
    public func storedValue() throws -> NSDate
      { self as NSDate }
    public static func decodeStoredValue(_ object: NSDate) throws -> Self
      { object as Self }
  }


extension Double : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .double }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.doubleValue }
  }


extension Float : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .float }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.floatValue }
  }


extension Int : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer64 }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.intValue }
  }


extension Int16 : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer16}
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.int16Value }
  }


extension Int32 : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer32 }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.int32Value }
  }


extension Int64 : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer64 }
    public func storedValue() throws -> NSNumber
      { self as NSNumber }
    public static func decodeStoredValue(_ object: NSNumber) throws -> Self
      { object.int64Value }
  }


extension String : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .string }
    public func storedValue() throws -> NSString
      { self as NSString }
    public static func decodeStoredValue(_ object: NSString) throws -> Self
      { object as Self }
  }


// MARK: - Any RawRepresentable is Storable when its RawValue is Storable -

extension RawRepresentable where RawValue : Storable
  {
    public static var attributeType: NSAttributeDescription.AttributeType
      { RawValue.attributeType }

    public func storedValue() throws -> RawValue.StoredType
      { try rawValue.storedValue() }

    public static func decodeStoredValue(_ storedValue: RawValue.StoredType) throws -> Self
      {
        let storedRawValue = try RawValue.decodeStoredValue(storedValue)
        guard let value = Self(rawValue: storedRawValue) else { throw Exception("'\(storedRawValue)' is not an acceptible raw value of \(Self.self)") }
        return value
      }
  }


// MARK: An Optional is Storable when its Wrapped value is Storable --

extension Optional : Storable where Wrapped : Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { Wrapped.attributeType }

    public func storedValue() throws -> Wrapped.StoredType?
      {
        switch self {
          case .some(let wrapped) : return try wrapped.storedValue()
          case .none : return nil
        }
      }

    public static func decodeStoredValue(_ storedValue: Wrapped.StoredType?) throws -> Self
      {
        switch storedValue {
          case .some(let storedValue) : return try Wrapped.decodeStoredValue(storedValue)
          case .none : return nil
        }
      }

    public static var isOptional : Bool
      { true }

    public static var nullValue : Self
      { .none }

    public var isNullValue : Bool
      {
        guard case .none = self else { return false }
        return true
      }
  }
