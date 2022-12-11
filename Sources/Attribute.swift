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


    /// Create an instance representing a (CoreData-) native value type.
    public init<T>(_ attname: String, nativeType: T.Type, ingestKey key: IngestKey? = nil, defaultValue v: T? = nil) where T : NativeType
      {
        name = attname
        nativeAttributeType = T.attributeType
        ingestKey = key ?? .element(name)
        ingestMethod = { try T.attributeType.createNSObject(from: $0) }
        defaultIngestValue = v?.asNSObject
        allowsNilValue = false
      }


    /// Create an instance representing a non-native value type encoded as data.
    public init<T>(_ attname: String, codableType: T.Type, ingestKey key: IngestKey? = nil, defaultValue v: T? = nil) where T : Ingestible & Codable
      {
        name = attname
        nativeAttributeType = nil
        ingestKey = key ?? .element(name)
        ingestMethod = { try T.createNSData(from: $0) }
        defaultIngestValue = try? v.map { try JSONEncoder().encode($0) as NSData }
        allowsNilValue = T.isNullable
      }


    public init<T,V>(_ attname: String, codableType: V.Type, ingestKey key: IngestKey? = nil, transform t: T, defaultValue v: V? = nil) where V : Ingestible & Codable, T : IngestTransform, T.Output == V.Input
      {
        name = attname
        nativeAttributeType = nil
        ingestKey = key ?? .element(name)
        defaultIngestValue = try? v.map { try JSONEncoder().encode($0) as NSData }
        allowsNilValue = V.isNullable
        ingestMethod = { json in
          guard let input = json as? T.Input else { throw Exception("expecting input of type '\(T.self)'") }
          return try V.createNSData(from: try t.transform(input))
        }
      }


    public var coreDataStorageType : NSAttributeDescription.AttributeType
      { nativeAttributeType ?? .binaryData }
  }
