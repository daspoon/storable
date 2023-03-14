/*

  Created by David Spooner

*/


/// The Nullable protocol is required to restrict the generic type parameter of OptionalAttribute to Optional.

public protocol Nullable : ExpressibleByNilLiteral
  {
    associatedtype Wrapped

    /// Create a Nullable value from an underlying value.
    static func inject(_ value: Wrapped) -> Self

    /// Return the underlying value of a Nullable value, if any.
    static func project(_ nullable: Self) -> Wrapped?
  }


extension Optional : Nullable
  {
    public static func inject(_ value: Wrapped) -> Self
      { Self(value) }

    public static func project(_ valueOrNil: Self) -> Wrapped?
      { valueOrNil }
  }
