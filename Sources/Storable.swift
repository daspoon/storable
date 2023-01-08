/*

*/

import CoreData


// NativeStorable identifies types which are supported directly by CoreData attribute storage.
// The nullValue methods is required to retrieve property values of optional type.

public protocol NativeStorable
  {
    static var attributeType : NSAttributeDescription.AttributeType { get }

    static var isOptional : Bool { get }

    static var nullValue : Self { get }
  }


// Storable identifies types which can be transformed to and from natively storable types and will serve as the constraint on our managed attribute types.

public protocol Storable
  {
    associatedtype StoredType : NativeStorable

    func storedValue() throws -> StoredType

    static func decodeStoredValue(_ storedValue: StoredType) throws -> Self
  }


// An Optional type is NativeStorable when its wrapped type is NativeStorable.
// NOTE: how is T?? not problematic...

extension Optional : NativeStorable where Wrapped : NativeStorable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { Wrapped.attributeType }

    public static var isOptional : Bool
      { true }

    public static var nullValue : Self
      { .none }
  }


// We simplify NativeStorable conformance for non-optional types with an extension.

extension NativeStorable
  {
    public static var isOptional : Bool
      { false }

    public static var nullValue : Self
      { fatalError("required when isOptional returns true") }
  }


// Any natively storable type is storable, although conformance must be declared explicitly.

extension NativeStorable
  {
    public func storedValue() throws -> Self
      { self }

    public static func decodeStoredValue(_ value: Self) throws -> Self
      { value }
  }


extension Bool : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .boolean }
  }


extension Data : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .binaryData }
  }


extension Date : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .date }
  }


extension Double : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .double }
  }


extension Float : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .float }
  }


extension Int : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension Int16 : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer16}
  }


extension Int32 : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer32 }
  }


extension Int64 : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension String : NativeStorable, Storable
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .string }
  }


// A RawRepresentable is Storable when its RawValue is natively storable; conformance must be declared explicitly.

extension RawRepresentable where RawValue : NativeStorable
  {
    public typealias NativeType = RawValue

    public func storedValue() throws -> RawValue
      { try rawValue.storedValue() }

    public static func decodeStoredValue(_ storedValue: RawValue) throws -> Self
      {
        let storedRawValue = try RawValue.decodeStoredValue(storedValue)
        guard let value = Self(rawValue: storedRawValue) else { throw Exception("'\(storedRawValue)' is not an acceptible raw value of \(Self.self)") }
        return value
      }
  }


// An Optional is Storable when its wrapped value is Storable.

extension Optional : Storable where Wrapped : Storable
  {
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
  }
