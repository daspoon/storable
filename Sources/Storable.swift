/*

*/

import CoreData


public protocol Storable
  {
    associatedtype StoredType : Storage

    static func storedValue(for value: Self) throws -> StoredType

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
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.boolValue }
  }

extension Data : Storable
  {
    public static func storedValue(for value: Self) throws -> NSData { value as NSData }
    public static func decodeStoredValue(_ storedValue: NSData) throws -> Self { storedValue as Self }
  }

extension Date : Storable
  {
    public static func storedValue(for value: Self) throws -> NSDate { value as NSDate }
    public static func decodeStoredValue(_ storedValue: NSDate) throws -> Self { storedValue as Self }
  }

extension Double : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.doubleValue }
  }

extension Float : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.floatValue }
  }

extension Int : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.intValue }
  }

extension Int16 : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.int16Value }
  }

extension Int32 : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.int32Value }
  }

extension Int64 : Storable
  {
    public static func storedValue(for value: Self) throws -> NSNumber { NSNumber(value: value) }
    public static func decodeStoredValue(_ storedValue: NSNumber) throws -> Self { storedValue.int64Value }
  }

extension String : Storable
  {
    public static func storedValue(for value: Self) throws -> NSString { value as NSString }
    public static func decodeStoredValue(_ storedValue: NSString) throws -> Self { storedValue as Self }
  }


// MARK: - NSManagedObject and Set<T: NSManagedObject> are Storable -

extension NSManagedObject : Storable
  {
    public static func storedValue(for object: NSManagedObject) throws -> NSManagedObject { object }
    public static func decodeStoredValue(_ object: NSManagedObject) throws -> Self { object as! Self }
  }


extension Set : Storable where Element : NSManagedObject
  {
    public static func storedValue(for set: Self) throws -> Self { set }
    public static func decodeStoredValue(_ set: Self) throws -> Self { set }
  }


// MARK: - Any Codable is Storable as Data, but conformance must be specified by concrete types -

extension Encodable
  {
    public static func storedValue(for value: Self) throws -> NSData
      { try! JSONEncoder().encode(value) as NSData }
  }

extension Decodable
  {
    public static func decodeStoredValue(_ data: NSData) throws -> Self
      { try! JSONDecoder().decode(Self.self, from: data as Data) }
  }


// MARK: - Any RawRepresentable is Storable when its RawValue is Storable -

extension RawRepresentable where RawValue : Storable
  {
    public static func storedValue(for value: Self) throws -> RawValue.StoredType
      { try RawValue.storedValue(for: value.rawValue) }

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
    public static func storedValue(for value: Self) throws -> Wrapped.StoredType?
      {
        switch value {
          case .some(let wrapped) : return try Wrapped.storedValue(for: wrapped)
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


// MARK: - Concrete collection types are Storable as Data when their elements are Codable -

extension Array : Storable where Element : Codable
  { }


extension Dictionary : Storable where Key : Codable, Value : Codable
  { }
