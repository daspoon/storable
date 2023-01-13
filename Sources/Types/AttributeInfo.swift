/*

*/

import CoreData


/// AttributeInfo represents an managed attribute declared via the Attribute property wrapper. It is essentially an enhancement of NSAttributeDescription which maintains additional data required for object ingestion.

public struct AttributeInfo : PropertyInfo
  {
    /// The managed property name.
    public let name : String

    /// The CoreData attribute storage type..
    public let attributeType : NSAttributeDescription.AttributeType

    /// Non-nil when attributeType is 'transformable'
    public let valueTransformerName : NSValueTransformerName?

    /// The optional default value.
    public let defaultValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool

    /// If non-nil, determines how json values are extracted from object ingest data and transformed to stored values.
    public let ingest : (key: IngestKey, method: (Any) throws -> any Storable)?


    public init(name: String, type: NSAttributeDescription.AttributeType, transformerName: NSValueTransformerName? = nil, defaultValue: (any Storable)? = nil, allowsNilValue: Bool = false, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        precondition((type == .transformable) == (transformerName != nil))

        self.name = name
        self.attributeType = type
        self.valueTransformerName = transformerName
        self.defaultValue = defaultValue
        self.allowsNilValue = allowsNilValue
        self.ingest = ingest
      }
  }
