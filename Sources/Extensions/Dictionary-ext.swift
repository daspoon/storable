/*

*/


extension Dictionary where Key == String, Value == Any
  {
    public func requiredValue<V>(of _: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V
      {
        guard let u = self[key] else { throw ConfigurationError.missingAttributeValue(key: key, context: context()) }
        guard let v = u as? V else { throw ConfigurationError.illTypedAttributeValue(key: key, context: context(), expectedType: "\(V.self)") }
        return v
      }

    public func requiredValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}(), transformedBy transform: (U) throws -> V?) throws -> V
      {
        let u: U = try requiredValue(for: key, in: context())
        guard let v: V = try transform(u) else { throw ConfigurationError.invalidAttributeValue(key: key, context: context()) }
        return v
      }

    public func optionalValue<V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}()) throws -> V?
      {
        guard let u = self[key] else { return nil }
        guard let v = u as? V else { throw ConfigurationError.illTypedAttributeValue(key: key, context: context(), expectedType: "\(V.self)") }
        return v
      }

    public func optionalValue<U,V>(of type: V.Type = V.self, for key: String, in context: @autoclosure () -> String? = {nil}(), transformedBy transform: (U) throws -> V?) throws -> V?
      {
        guard let u: U = try optionalValue(for: key, in: context()) else { return nil }
        guard let v: V = try transform(u) else { throw ConfigurationError.invalidAttributeValue(key: key, context: context()) }
        return v
      }
  }
