/*

*/


public protocol Defaultable
  {
    /// Return a Swift literal expression of the receiver.
    var asSwiftLiteral : String { get }
  }


// MARK: --

extension Array : Defaultable where Element : Defaultable
  {
    public var asSwiftLiteral : String
      { "[" + map({$0.asSwiftLiteral}).joined(separator: ", ") + "]" }
  }


extension Bool : Defaultable
  {
    public var asSwiftLiteral : String
      { "\(self)" }
  }


extension Dictionary : Defaultable where Key == String, Value : Defaultable
  {
    public var asSwiftLiteral : String
      { "[" + map({$0.asSwiftLiteral + ": " + $1.asSwiftLiteral}).joined(separator: ", ") + "]" }
  }


extension Numeric
  {
    public var asSwiftLiteral : String
      { "\(self)" }
  }

extension Int : Defaultable {}
extension Int8 : Defaultable {}
extension Int16 : Defaultable {}
extension Int32 : Defaultable {}
extension Int64 : Defaultable {}
extension Float : Defaultable {}
extension Double : Defaultable {}
extension UInt : Defaultable {}
extension UInt8 : Defaultable {}
extension UInt16 : Defaultable {}
extension UInt32 : Defaultable {}
extension UInt64 : Defaultable {}


extension Optional : Defaultable where Wrapped : Defaultable
  {
    public var asSwiftLiteral : String
      {
        switch self {
          case .none : return "nil"
          case .some(let wrapped) : return wrapped.asSwiftLiteral
        }
      }
  }


extension String : Defaultable
  {
    public var asSwiftLiteral : String
      { "\"" + self + "\"" }
  }
