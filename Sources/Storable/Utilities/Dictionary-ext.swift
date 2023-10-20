/*

  Created by David Spooner

*/


extension Dictionary
  {
    // The combine/combining methods enable useful error messages, unlike their counterparts in the standard library.

    /// Merge the given sequence of key/value pairs, invoking the given function to combine new and existing values.
    public mutating func combine<S: Sequence>(_ other: S, conflictResolution f: (Key, Value, Value) throws -> Value) rethrows where S.Element == (Key, Value)
      {
        for (key, value) in other {
          switch self[key] {
            case .some(let existing) :
              self[key] = try f(key, existing, value)
            case .none :
              self[key] = value
          }
        }
      }

    /// Return the result of mergeing the given sequence of key/value pairs, invoking the given function to combine new and existing values.
    public func combining<S: Sequence>(_ other: S, conflictResolution f: (Key, Value, Value) throws -> Value) rethrows -> Self where S.Element == (Key, Value)
      {
        var copy = self
        try copy.combine(other, conflictResolution: f)
        return copy
      }

    /// Merge the given sequence of key/value pairs, throwing if any given key already exists in the receiver.
    public mutating func combine<S: Sequence>(_ other: S) throws where S.Element == (Key, Value)
      { try combine(other, conflictResolution: { k,_,_ in throw Exception("multiple definitions for '\(k)'") }) }

    /// Return the result of mergeing the given sequence of key/value pairs, throwing if any given key already exists in the receiver.
    public func combining<S: Sequence>(_ other: S) throws -> Self where S.Element == (Key, Value)
      { try combining(other, conflictResolution: { k,_,_ in throw Exception("multiple definitions for '\(k)'") }) }
  }


/// Methods used to simplify extraction of object property values from JSON ingest data.

extension Dictionary where Key == String, Value == Any
  {
    public func optionalValue<V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V?
      {
        guard let u = self[key] else { return nil }
        guard let v = u as? V else { throw Exception.illTypedValue(key: key, type: type, in: context()) }
        return v
      }

    public func requiredValue<V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V
      {
        guard let v = try optionalValue(of: type, for: key, in: context()) else { throw Exception.missingValue(key: key, in: context()) }
        return v
      }

    public func optionalValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}(), transformedBy transform: (U) throws -> V?) throws -> V?
      {
        guard let u: U = try optionalValue(for: key, in: context()) else { return nil }
        guard let v: V = try transform(u) else { throw Exception.illFormedValue(key: key, in: context()) }
        return v
      }

    public func requiredValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}(), transformedBy transform: (U) throws -> V?) throws -> V
      {
        guard let v = try optionalValue(of: type, for: key, in: context(), transformedBy: transform) else { throw Exception.missingValue(key: key, in: context()) }
        return v
      }


#if false
// TODO: recast as custom implementation of Decoder, if necessary
    public func optionalValue<V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V? where V : Ingestible
      { try optionalValue(of: type, for: key, in: context(), transformedBy: { try V(json: $0)}) }

    public func requiredValue<V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V where V : Ingestible
      { try requiredValue(of: type, for: key, in: context(), transformedBy: { try V(json: $0)}) }


    public func optionalArrayValue<U,V>(of type: V.Type, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> [V]? where V : Ingestible, U == V.Input
      {
        guard let us : [U] = try optionalValue(for: key, in: context()) else { return nil }
        return try us.map { try V(json: $0) }
      }

    public func requiredArrayValue<U,V>(of type: V.Type, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> [V] where V : Ingestible, U == V.Input
      {
        guard let vs = try optionalArrayValue(of: type, for: key, in: context()) else { throw Exception.missingValue(key: key, in: context()) }
        return vs
      }


    public func optionalDictionaryValue<U,V>(of type: V.Type, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> [String: V]? where V : Ingestible, U == V.Input
      {
        guard let kus : [String: U] = try optionalValue(for: key, in: context()) else { return nil }
        return try kus.mapValues { try V(json: $0) }
      }

    public func requiredDictionaryValue<U,V>(of type: V.Type, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> [String: V] where V : Ingestible, U == V.Input
      {
        guard let kvs = try optionalDictionaryValue(of: type, for: key, in: context()) else { throw Exception.missingValue(key: key, in: context()) }
        return kvs
      }
#endif
  }
