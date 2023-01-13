/*

*/


/// Methods added to Dictionary to simplify ingestion of object property values from JSON.

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


    public func optionalValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V? where V : Ingestible, U == V.Input
      { try optionalValue(of: type, for: key, in: context(), transformedBy: { try V(json: $0)}) }

    public func requiredValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V where V : Ingestible, U == V.Input
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
  }
