/*

*/

import Foundation


/// DataSource determines how a data model is populated from json data residing in the associated bundle.
///
public struct DataSource
  {
    /// Content indentifies a json value used to ingest a set of object instances.
    public struct Content
      {
        public enum Format { case any, array, dictionary }

        /// The name of the json resource within the bundle.
        public let resourceName : String

        /// An optional key path leading to the asset value within the resource content. If specified, the resource content must be a dictionary.
        public let keyPath : String?

        /// The format of the asset content. Collections can be specified as either arrays of names or as dictionaries mapping names to entity-specific data.
        public let format : Format

        public init(resourceName name: String, keyPath path: String? = nil, format fmt: Format = .dictionary)
          { resourceName = name; keyPath = path; format = fmt }
      }


    /// Definition determines how json content translates to a set of object instances.
    public enum Definition
      {
        /// Corresponds to a set of instances of a named entity.
        case entitySet(name: String, content: Content? = nil)
      }


    let bundle : Bundle
    let definitions : [Definition]


    public init(bundle: Bundle, definitions: [Definition])
      {
        self.bundle = bundle
        self.definitions = definitions
      }


    /// Load the specified JSON value from the associated bundle.
    public func load<T>(_ content: Content, of type: T.Type = Any.self) throws -> T
      {
        guard let url = bundle.url(forResource: content.resourceName, withExtension: "json") else {
          throw Exception("json file '\(content.resourceName)' not found in bundle \(bundle.bundleIdentifier ?? "?")")
        }

        let data : Data
        do {
          try data = Data(contentsOf: url)
        }
        catch let error as NSError {
          throw Exception("failed to load data from '\(url.lastPathComponent)': " + error.localizedDescription)
        }

        var json : Any
        do {
          json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue:0))
        }
        catch let error as NSError {
          throw Exception("failed to decode json data from '\(url.lastPathComponent)': " + error.localizedDescription)
        }

        if let keyPath = content.keyPath {
          var prefix = ""
          for key in keyPath.components(separatedBy: ".") {
            guard let jsonDict = json as? [String: Any] else { throw Exception("failed to load key path '\(keyPath)' from \(url.lastPathComponent): value for key path '\(prefix)' is not a dictionary") }
            guard let value = jsonDict[key] else { throw Exception("failed to load key path '\(keyPath)' from \(url.lastPathComponent): no value for '\(key)'") }
            prefix = prefix + (prefix != "" ? "." : "") + key
            json = value
          }
        }
        guard let value = json as? T else {
          throw Exception("failed to interpret json data from '\(content.resourceName).json' as \(T.self)")
        }

        return value
      }
  }
