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


    public init<Value: Storable>(name: String, type: Value.Type, defaultValue: Value? = nil, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        self.name = name
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.allowsNilValue = Value.EncodingType.isOptional
        self.ingest = ingest
      }
  }
