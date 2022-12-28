/*

*/

import CoreData


/// Represents a managed object attribute.
public struct Attribute : Property
  {
    /// The managed property name.
    public let name : String

    /// Non-nil for native types.
    public let coreDataAttributeType : NSAttributeDescription.AttributeType

    /// The key used to extract the applicable json value from object ingest data.
    public let ingestKey : IngestKey

    /// The method used to translate the json ingest value to an object value persisted by CoreData.
    public let ingestMethod : (Any) throws -> any Storable

    /// The default when no value is provided on ingestion.
    public let defaultIngestValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool


    public init(name: String, type: NSAttributeDescription.AttributeType, ingestMethod: @escaping (Any) throws -> any Storable, ingestKey: IngestKey? = nil, allowsNilValue: Bool = false, defaultValue: Any? = nil)
      {
        self.name = name
        self.ingestMethod = ingestMethod
        self.ingestKey = ingestKey ?? .element(name)
        self.allowsNilValue = allowsNilValue
        self.coreDataAttributeType = type

        // TODO: report failure to ingest default value
        self.defaultIngestValue = defaultValue.flatMap { try? ingestMethod($0) }
      }
  }
