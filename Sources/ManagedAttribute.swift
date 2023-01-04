/*

*/

import CoreData


/// Represents a managed object attribute.
public struct ManagedAttribute : ManagedProperty
  {
    /// The managed property name.
    public let name : String

    /// Non-nil for native types.
    public let attributeType : NSAttributeDescription.AttributeType

    /// Indicates how json values are extracted from the data provided to the enclosing object on ingestion.
    public let ingestKey : IngestKey

    /// The method used to translate the json ingest value to an object value persisted by CoreData.
    public let ingestMethod : (Any) throws -> any Storable

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool

    /// The optional default value.
    public let defaultValue : (any Storable)?


    public init(name: String, type: NSAttributeDescription.AttributeType, ingestMethod: @escaping (Any) throws -> any Storable, ingestKey: IngestKey? = nil, allowsNilValue: Bool = false, defaultValue: (any Storable)? = nil)
      {
        self.name = name
        self.ingestKey = ingestKey ?? .element(name)
        self.ingestMethod = ingestMethod
        self.allowsNilValue = allowsNilValue
        self.attributeType = type
        self.defaultValue = defaultValue
      }
  }
