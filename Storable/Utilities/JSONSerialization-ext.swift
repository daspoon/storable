/*

  Created by David Spooner


import Foundation


extension JSONSerialization
  {
    /// Load the specified JSON value from the associated bundle.
    public static func load<T>(_ type: T.Type = Any.self, from data: Data, context: String? = nil, keyPath: String? = nil) throws -> T
      {
        var json : Any
        do {
          json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0))
        }
        catch let error as NSError {
          throw Exception("failed to decode data \(context.map({"from \($0)"}) ?? "") as JSON: " + ((error.userInfo["NSDebugDescription"] as? String) ?? error.description))
        }

        if let keyPath {
          var prefix = ""
          for key in keyPath.components(separatedBy: ".") {
            guard let jsonDict = json as? [String: Any] else { throw Exception("failed to load key path '\(keyPath)' \(context.map({"from \($0)"}) ?? ""): value for key path '\(prefix)' is not a dictionary") }
            guard let value = jsonDict[key] else { throw Exception("failed to load key path '\(keyPath)' \(context.map({"from \($0)"}) ?? ""): no value for '\(key)'") }
            prefix = prefix + (prefix != "" ? "." : "") + key
            json = value
          }
        }
        guard let value = json as? T else {
          throw Exception("failed to interpret json data as \(T.self)")
        }

        return value
      }

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
*/
