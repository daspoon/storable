/*

  Created by David Spooner

*/

import CoreData


/// Methods added to NSManagedObject for use in migration scripts.

extension NSManagedObject
  {
    /// Retrieve an optional attribute value of StorableAsData type T. Throws if the stored value is neither nil nor a (transformed) instance of a Boxed<T>.
    public func optionalUnboxedValue<T: Codable>(of t: T.Type = T.self, forKey key: String) throws -> T?
      {
        guard let storedValue = value(forKey: key) else { return nil }
        guard let boxedValue = storedValue as? Boxed<T> else {
          throw Exception("expected type \(t) for '\(key)' of '\(type(of: self))'; found \(type(of: storedValue))")
        }
        return boxedValue.value
      }

    /// Retrieve an attribute value of StorableAsData type T. Throws if the stored value is not an instance of Boxed<T>.
    public func unboxedValue<T: Codable>(of t: T.Type = T.self, forKey key: String) throws -> T
      {
        guard let value = try optionalUnboxedValue(of: t, forKey: key) else {
          throw Exception("expected non-nil value for '\(key)' of '\(type(of: self))'")
        }
        return value
      }

    /// Set the value of attribute of StorableAsData type T.
    public func setBoxedValue<T: Codable>(_ value: T, forKey key: String)
      {
        setValue(Boxed(value: value), forKey: key)
      }
  }
