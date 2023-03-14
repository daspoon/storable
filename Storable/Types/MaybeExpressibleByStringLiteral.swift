/*

  Created by David Spooner.

*/


/// MaybeExpressibleByStringLiteral identifies types with a failable init method taking a single string argument.

public protocol MaybeExpressibleByStringLiteral
  {
    init?(_ string: String)
  }


/// Provide an extension method to serve as an ingest transform.

extension MaybeExpressibleByStringLiteral
  {
    public static func with(string s: String) throws -> Self
      {
        guard let value = Self(s) else { throw Exception("expecting \(Self.self) value") }
        return value
      }
  }


/// Define conformance for some basic types.

extension Bool : MaybeExpressibleByStringLiteral {}
extension Double : MaybeExpressibleByStringLiteral {}
extension Float : MaybeExpressibleByStringLiteral {}
extension Int : MaybeExpressibleByStringLiteral {}
extension Int16 : MaybeExpressibleByStringLiteral {}
extension Int32 : MaybeExpressibleByStringLiteral {}
extension Int64 : MaybeExpressibleByStringLiteral {}
