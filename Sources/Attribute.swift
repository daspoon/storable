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

    public let ingestAction : IngestAction

    /// The method used to translate the json ingest value to an object value persisted by CoreData.
    public let ingestMethod : (Any) throws -> any Storable

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool


    public init(name: String, type: NSAttributeDescription.AttributeType, ingestMethod: @escaping (Any) throws -> any Storable, ingestKey: IngestKey? = nil, allowsNilValue: Bool = false, defaultValue v: Any? = nil)
      {
        // TODO: report failure to ingest default value
        self.name = name
        self.ingestAction = .ingest(key: ingestKey ?? .element(name), defaultValue: v.flatMap { try? ingestMethod($0) })
        self.ingestMethod = ingestMethod
        self.allowsNilValue = allowsNilValue
        self.coreDataAttributeType = type
      }
  }
