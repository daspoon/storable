/*

*/

import CoreData


// Storable identifies types which can be transformed to and from AttributeType, and serves as the generic constraint for our attribute property wrapper.

public protocol Storable
  {
    associatedtype EncodingType : AttributeType

    /// Encode a value into its stored representation.
    func storedValue() -> EncodingType

    /// Decode a stored value back to its native representation.
    static func decodeStoredValue(_ storedValue: EncodingType) -> Self

    /// Indicates whether or not the translation from stored to native type should be cached.
    static var valueTransformerName : NSValueTransformerName? { get }
  }


// All attribute types are trivially Storable, although conformance must be declared explicitly.

extension AttributeType
  {
    public func storedValue() -> Self
      { self }

    public static func decodeStoredValue(_ value: Self) -> Self
      { value }

    public static var valueTransformerName : NSValueTransformerName?
      { nil }
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
extension URL : Storable {}
extension UUID : Storable {}


// An Optional is Storable when its wrapped value is Storable, although the required type constraints are complicated by the constraints on Optional's conformance to AttributeType.

extension Optional : Storable where Wrapped : Storable, Wrapped.EncodingType.StorageType == Wrapped, Wrapped.EncodingType == Wrapped
  {
    public func storedValue() -> Wrapped.EncodingType?
      {
        switch self {
          case .some(let wrapped) : return wrapped.storedValue()
          case .none : return nil
        }
      }

    public static func decodeStoredValue(_ storedValue: Wrapped.EncodingType?) -> Self
      {
        switch storedValue {
          case .some(let storedValue) : return Wrapped.decodeStoredValue(storedValue)
          case .none : return nil
        }
      }

    public static var valueTransformerName : NSValueTransformerName?
      { Wrapped.valueTransformerName }
  }


// A RawRepresentable is Storable when its RawValue is an attribute type, although conformance must be declared explicitly on concrete types.

extension RawRepresentable where RawValue : AttributeType
  {
    public func storedValue() -> RawValue
      { rawValue }

    public static func decodeStoredValue(_ storedValue: RawValue) -> Self
      {
        guard let value = Self(rawValue: storedValue) else { fatalError("'\(storedValue)' is not an acceptible raw value of \(Self.self)") }
        return value
      }

    public static var valueTransformerName : NSValueTransformerName?
      { nil }
  }
