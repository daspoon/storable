/*

*/


/// A custom protocol used to identify optional types.
public protocol Nullable : ExpressibleByNilLiteral
  {
    associatedtype Wrapped

    static func inject(_ value: Wrapped) -> Self

    var project : Wrapped? { get }
  }


extension Optional : Nullable
  {
    public static func inject(_ value: Wrapped) -> Self
      { .some(value) }

    public var project : Wrapped?
      { self }
  }
