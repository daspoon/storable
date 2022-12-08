/*

*/

import Foundation


public protocol Ingestible : Encodable
  {
    associatedtype Input

    init(json: Input) throws
  }


extension Ingestible
  {
    public static func createNSData(from json: Any) throws -> NSData
      {
        guard let value = json as? Input else { throw Exception("expecting value of type \(Input.self)") }
        return try JSONEncoder().encode(try Self(json: value)) as NSData
      }
  }


// MARK: --
// Implement the Ingestible requirements on RawRepresentable to enable conformance for enum types.

extension RawRepresentable
  {
    public init(json v: RawValue) throws
      {
        guard let value = Self(rawValue: v) else { throw Exception("invalid value of \(Self.self): '\(v)'") }
        self = value
      }
  }



// MARK: --
// Implement Ingestible on commonly used types which are representable as JSON.

extension Array : Ingestible where Element : Ingestible
  {
    public init(json: [Element.Input]) throws
      {
        self = try json.map { try Element(json: $0) }
      }
  }


extension Dictionary : Ingestible where Key == String, Value : Ingestible
  {
    public init(json: [String: Value.Input]) throws
      {
        self = Dictionary(uniqueKeysWithValues: try json.map { ($0, try Value(json: $1)) })
      }
  }


extension Numeric
  {
    public init(json: Any) throws
      {
        guard let value = json as? Self else { throw Exception("expecting \(Self.self) value") };
        self = value
      }
  }

extension Int : Ingestible {}
extension Int8 : Ingestible {}
extension Int16 : Ingestible {}
extension Int32 : Ingestible {}
extension Int64 : Ingestible {}
extension Float : Ingestible {}
extension Double : Ingestible {}
extension UInt : Ingestible {}
extension UInt8 : Ingestible {}
extension UInt16 : Ingestible {}
extension UInt32 : Ingestible {}
extension UInt64 : Ingestible {}


extension Optional : Ingestible where Wrapped : Ingestible
  {
    public init(json: Wrapped.Input) throws
      {
        self = .some(try Wrapped(json: json))
      }
  }


extension String : Ingestible
  {
    public init(json: Any) throws
      {
        guard let value = json as? Self else { throw Exception("expecting \(Self.self) value") };
        self = value
      }
  }