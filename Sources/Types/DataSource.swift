/*

  Created by David Spooner

*/

import Foundation


/// DataSource determines how a data model is populated from json data residing in the associated bundle.

public struct DataSource
  {
    /// Content indentifies a json value used to ingest a set of object instances.
    public struct Content
      {
        /// The name of the json resource within the bundle.
        public let resourceName : String

        /// An optional key path leading to the asset value within the resource content. If specified, the resource content must be a dictionary.
        public let keyPath : String?

        /// The format of the asset content. Collections can be specified as either arrays of names or as dictionaries mapping names to entity-specific data.
        public let format : ClassInfo.IngestFormat

        public init(resourceName name: String, keyPath path: String? = nil, format fmt: ClassInfo.IngestFormat = .dictionary)
          { resourceName = name; keyPath = path; format = fmt }

        public var resourceNameAndKeyPath : String
          { resourceName + (keyPath.map {"/" + $0} ?? "") }
      }


    let bundle : DataBundle
    let definitions : [DataDefinition]


    public init(bundle: DataBundle, definitions: [DataDefinition])
      {
        self.bundle = bundle
        self.definitions = definitions
      }


    /// Load the specified JSON value from the associated bundle.
    public func load<T>(_ content: Content, of type: T.Type = Any.self) throws -> T
      {
        let data = try bundle.jsonData(for: content.resourceName)
        return try JSONSerialization.load(type, from: data, keyPath: content.keyPath)
      }
  }
