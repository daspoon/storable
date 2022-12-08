/*

*/

import CoreData


// MARK: --



// MARK: --

/// Represents a managed object attribute.
public struct Attribute : Property
  {
    /// The managed property name.
    public let name : String

    /// Non-nil for native types.
    public let nativeAttributeType : NSAttributeDescription.AttributeType?

    /// The key and method used to extract the property value from json input and translate that value to a object type supported by CoreData.
    public let ingest : (key: IngestKey, method: (Any) throws -> NSObject)?


    /// Create an instance representing a (CoreData-) native value type.
    public init<T>(_ attname: String, ofNativeType _: T.Type, ingestKey key: IngestKey?) where T : NativeType
      {
        name = attname
        nativeAttributeType = T.attributeType
        ingest = key.map { (key: $0, method: { try T.attributeType.createNSObject(from: $0) })}
      }


    /// Create an instance representing a non-native value type encoded as data.
    public init<T>(_ attname: String, ofCodableType _: T.Type, ingestKey key: IngestKey?) where T : Ingestible & Codable
      {
        name = attname
        nativeAttributeType = nil
        ingest = key.map { (key: $0, method: { try T.createNSData(from: $0) }) }
      }


    public var ingested : Bool
      { ingest != nil }


    public var optional : Bool
      { fatalError() }


    public func ingest(json: Any) throws -> NSObject
      {
        guard let ingest else { throw Exception("attribute is specified as non-ingestible") }
        return try ingest.method(json)
      }


    public var coreDataStorageType : NSAttributeDescription.AttributeType
      { nativeAttributeType ?? .binaryData }
  }
