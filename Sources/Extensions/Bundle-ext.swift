/*

*/

import Foundation


extension Bundle
  {
    enum JSONError : Error
      {
        case accessError(name: String, reason: String)
        case syntaxError(name: String, reason: String)
        case typeError(name: String, expectedType: String)

        var localizedDescription : String
          {
            switch self {
              case .accessError(name: let name, reason: let reason) :
                return "Failed to access '\(name).json' -- \(reason)"
              case .syntaxError(name: let name, reason: let reason) :
                return "Failed to parse '\(name).json' -- \(reason)"
              case .typeError(name: let name, expectedType: let type) :
                return "Content of '\(name).json' is not of the expected type '\(type)'"
            }
          }
      }

    /// Load JSON data of the specified type from the named file within the receiving bundle.
    public func loadJSON<T>(_ name: String, ofType _: T.Type = [String: Any].self) throws -> T
      {
        guard let url = url(forResource: name, withExtension: "json") else {
          throw JSONError.accessError(name: name, reason: "file not found")
        }

        let data : Data
        do { try data = Data(contentsOf: url) }
        catch let error as NSError {
          throw JSONError.accessError(name: name, reason: error.localizedDescription)
        }

        let json : Any
        do { json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0)) }
        catch let error as NSError {
          throw JSONError.syntaxError(name: name, reason: error.localizedFailureReason ?? error.localizedDescription)
        }

        guard let value = json as? T else {
          throw JSONError.typeError(name: name, expectedType: "\(T.self)")
        }

        return value
      }

    public func attributedTextForResource(_ name: String) -> NSAttributedString!
      {
        guard let url = Bundle.main.url(forResource: name, withExtension: "rtf") else { return nil }
        return try? NSAttributedString(url: url, documentAttributes: nil)
      }
  }
