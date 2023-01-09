/*

*/

import CoreData


// Storable identifies types which can be transformed to and from AttributeType, and serves as the generic constraint for our attribute property wrapper.

public protocol Storable
  {
    associatedtype EncodingType : AttributeType

    /// Encode a value into its stored representation.
    func storedValue() throws -> EncodingType

    /// Decode a stored value back to its
    static func decodeStoredValue(_ storedValue: EncodingType) throws -> Self
  }


// All attribute types are trivially Storable, although conformance must be declared explicitly.

extension AttributeType
  {
    public func storedValue() throws -> Self
      { self }

    public static func decodeStoredValue(_ value: Self) throws -> Self
      { value }
  }

extension Bool : Storable {}
extension Data : Storable {}
extension Date : Storable {}
extension Double : Storable {}
extension Float : Storable {}
extension Int : Storable {}
extension Int16 : Storable {}
extension Int32 : Storable {}
extension Int64 : Storable {}
extension String : Storable {}


// An Optional is Storable when its wrapped value is Storable, although the required type constraints are complicated by the constraints on Optional's conformance to AttributeType.

extension Optional : Storable where Wrapped : Storable, Wrapped.EncodingType.StorageType == Wrapped, Wrapped.EncodingType == Wrapped
  {
    public func storedValue() throws -> Wrapped.EncodingType?
      {
        switch self {
          case .some(let wrapped) : return try wrapped.storedValue()
          case .none : return nil
        }
      }

    public static func decodeStoredValue(_ storedValue: Wrapped.EncodingType?) throws -> Self
      {
        switch storedValue {
          case .some(let storedValue) : return try Wrapped.decodeStoredValue(storedValue)
          case .none : return nil
        }
      }
  }


// A RawRepresentable is Storable when its RawValue is an attribute type, although conformance must be declared explicitly on concrete types.

extension RawRepresentable where RawValue : AttributeType
  {
    public func storedValue() throws -> RawValue
      { rawValue }

    public static func decodeStoredValue(_ storedValue: RawValue) throws -> Self
      {
        guard let value = Self(rawValue: storedValue) else { throw Exception("'\(storedValue)' is not an acceptible raw value of \(Self.self)") }
        return value
      }
  }
