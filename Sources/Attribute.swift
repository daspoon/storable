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


    private init(name: String, type: NSAttributeDescription.AttributeType, ingestMethod: @escaping (Any) throws -> any Storable, ingestKey: IngestKey? = nil, allowsNilValue: Bool = false, defaultValue: Any? = nil)
      {
        self.name = name
        self.ingestMethod = ingestMethod
        self.ingestKey = ingestKey ?? .element(name)
        self.allowsNilValue = allowsNilValue
        self.coreDataAttributeType = type

        // TODO: report failure to ingest default value
        self.defaultIngestValue = defaultValue.flatMap { try? ingestMethod($0) }
      }


    /// Create an instance representing a (CoreData-) native value type.
    public init<V>(_ attname: String, of: V.Type, ingestKey key: IngestKey? = nil, defaultValue v: V? = nil) where V : Ingestible & Storable
      {
        func ingest(_ json: Any) throws -> V {
          try V(json: try throwingCast(json))
        }
        self.init(name: attname, type: V.attributeType, ingestMethod: ingest, ingestKey: key, defaultValue: v)
      }

    /// Create an instance representing a non-native value type, with an ingest transform.
    public init<T, V>(_ attname: String, of: V.Type, ingestKey key: IngestKey? = nil, transform t: T, defaultValue v: T.Input? = nil) where V : Ingestible & Storable, T : IngestTransform, T.Output == V.Input
      {
        func ingest(_ json: Any) throws -> V {
          try V(json: try t.transform(try throwingCast(json)))
        }
        self.init(name: attname, type: V.attributeType, ingestMethod: ingest, ingestKey: key, allowsNilValue: V.isOptional, defaultValue: v)
      }
  }
