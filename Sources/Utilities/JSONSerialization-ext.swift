/*

*/

import Foundation


extension JSONSerialization
  {
    /// Return the JSON value for the given string, throwing on failure.
    public static func jsonObject(with text: String, encoding: String.Encoding = .utf8, options: ReadingOptions = []) throws -> Any
      {
        guard let data = text.data(using: encoding) else { throw Exception("failed to encode text as \(encoding)") }
        return try jsonObject(with: data, options: options)
      }

    /// Return the JSON value of the specified type from the given data, throwing on failure.
    public static func jsonObject<T>(of type: T.Type = T.self, from data: Data, options: ReadingOptions = []) throws -> T
      {
        let json = try jsonObject(with: data, options: options)
        guard let value = json as? T else { throw Exception("failed to interpret json data as \(T.self)") }
        return value
      }
  }
