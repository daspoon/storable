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


    /// Create an instance representing a (CoreData-) native value type.
    public init<T>(_ attname: String, nativeType: T.Type, ingestKey key: IngestKey? = nil) where T : NativeType
      {
        name = attname
        nativeAttributeType = T.attributeType
        ingestKey = key ?? .element(name)
        ingestMethod = { try T.attributeType.createNSObject(from: $0) }
      }


    /// Create an instance representing a non-native value type encoded as data.
    public init<T>(_ attname: String, codableType: T.Type, ingestKey key: IngestKey?) where T : Ingestible & Codable
      {
        name = attname
        nativeAttributeType = nil
        ingestKey = key ?? .element(name)
        ingestMethod = { try T.createNSData(from: $0) }
      }


    public var optional : Bool
      {
// TODO: determine attribute type
fatalError()
      }


    public var coreDataStorageType : NSAttributeDescription.AttributeType
      { nativeAttributeType ?? .binaryData }
  }
