/*

*/

import CoreData


/// Represents a managed object attribute.
public struct AttributeInfo : PropertyInfo
  {
    /// The managed property name.
    public let name : String

    /// Non-nil for native types.
    public let attributeType : NSAttributeDescription.AttributeType

    /// The optional default value.
    public let defaultValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool

    /// If non-nil, determines how json values are extracted from object ingest data and transformed to stored values.
    public let ingest : (key: IngestKey, method: (Any) throws -> any Storable)?


    public init(name: String, type: NSAttributeDescription.AttributeType, defaultValue: (any Storable)? = nil, allowsNilValue: Bool = false, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        self.name = name
        self.attributeType = type
        self.defaultValue = defaultValue
        self.allowsNilValue = allowsNilValue
        self.ingest = ingest
      }
  }
