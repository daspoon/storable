/*

*/

import CoreData


/// Represents a managed object attribute.
public struct Attribute : Property
  {
    /// The managed property name.
    public let name : String

    /// Non-nil for native types.
    public let nativeAttributeType : NSAttributeDescription.AttributeType?

    /// The key used to extract the applicable json value from object ingest data.
    public let ingestKey : IngestKey

    /// The method used to translate the json ingest value to an object value persisted by CoreData.
    public let ingestMethod : (Any) throws -> NSObject

    /// The default when no value is provided on ingestion.
    public let defaultIngestValue : NSObject?

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool


    private init(name: String, ingestMethod: @escaping (Any) throws -> NSObject, ingestKey: IngestKey? = nil, allowsNilValue: Bool = false, nativeAttributeType: NSAttributeDescription.AttributeType? = nil, defaultValue: Any? = nil)
      {
        self.name = name
        self.ingestMethod = ingestMethod
        self.ingestKey = ingestKey ?? .element(name)
        self.allowsNilValue = allowsNilValue
        self.nativeAttributeType = nativeAttributeType

        // TODO: report failure to ingest default value
        self.defaultIngestValue = defaultValue.flatMap { try? ingestMethod($0) }
      }


    /// Create an instance representing a (CoreData-) native value type.
    public init<T>(_ attname: String, nativeType: T.Type, ingestKey key: IngestKey? = nil, defaultValue v: T? = nil) where T : NativeType
      {
        self.init(name: attname, ingestMethod: {try T.attributeType.createNSObject(from: $0)}, ingestKey: key, nativeAttributeType: T.attributeType, defaultValue: v)
      }


    /// Create an instance representing a non-native value type encoded as data.
    public init<T>(_ attname: String, codableType: T.Type, ingestKey key: IngestKey? = nil, defaultValue v: T? = nil) where T : Ingestible & Codable
      {
        self.init(name: attname, ingestMethod: {try T.createNSData(from: $0)}, ingestKey: key, allowsNilValue: T.isNullable, defaultValue: v)
      }


    /// Create an instance representing a non-native value type, with an ingest transform.
    public init<T,V>(_ attname: String, codableType: V.Type, ingestKey key: IngestKey? = nil, transform t: T, defaultValue v: T.Input? = nil) where V : Ingestible & Codable, T : IngestTransform, T.Output == V.Input
      {
        self.init(name: attname, ingestMethod: {try V.createNSData(from: try t.transform(try throwingCast($0)))}, ingestKey: key, allowsNilValue: V.isNullable, defaultValue: v)
      }


    public var coreDataStorageType : NSAttributeDescription.AttributeType
      { nativeAttributeType ?? .binaryData }
  }
