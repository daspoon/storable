/*

*/


/// A custom protocol used to identify optional types.
public protocol Nullable : ExpressibleByNilLiteral
  {
    associatedtype Element
  }


extension Optional : Nullable
  {
    public typealias Element = Wrapped
  }
