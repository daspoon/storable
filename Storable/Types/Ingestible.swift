/*

  Created by David Spooner

*/

import Foundation


/// Ingestible identifies data types which can be created from JSON.

public protocol Ingestible
  {
    /// The associated JSON type.
    associatedtype Input

    /// Initialize a new value from a JSON value. Required.
    init(json: Input) throws
  }


extension Ingestible
  {
    /// Attempt to create an instance from the given json value. An exception is raised if the argument value is not of the Input type.
    static func ingest(_ json: Any) throws -> Self
      { try Self(json: try throwingCast(json)) }

    /// Attempt to create an instance from the given json value after applying the given transform. An exception is raised if the argument value is not of the transform's Input type.
    static func ingest<Alt>(_ json: Any, withTransform f: (Alt) throws -> Input) throws -> Self
      { try Self(json: try f(try throwingCast(json))) }
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


extension Bool : Ingestible
  {
    public init(json value: Bool) throws
      { self = value }
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
    public init(json number: Self) throws
      { self = number }
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
    public init(json: Wrapped.Input?) throws
      { self = try json.map { try Wrapped(json: $0) } }
  }


extension String : Ingestible
  {
    public init(json string: String) throws
      { self = string }
  }
