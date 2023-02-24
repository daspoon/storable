/*

*/

import CoreData


/// AttributeInfo represents an managed attribute declared via the Attribute property wrapper. It is essentially an enhancement of NSAttributeDescription which maintains additional data required for object ingestion.

public struct AttributeInfo : PropertyInfo
  {
    /// The managed property name.
    public var name : String

    /// The Storable value type provided on initialization.
    public var type : Any.Type

    /// The CoreData attribute storage type..
    public var attributeType : NSAttributeDescription.AttributeType

    /// Non-nil when attributeType is 'transformable'
    public var valueTransformerName : NSValueTransformerName?

    /// The optional default value.
    public var defaultValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public var isOptional : Bool

    /// The name of the attribute in the previous entity version, if necessary.
    public var renamingIdentifier : String?

    /// If non-nil, determines how json values are extracted from object ingest data and transformed to stored values.
    public var ingest : (key: IngestKey, method: (Any) throws -> any Storable)?


    public init<Value: Storable>(name: String, type: Value.Type, isOptional: Bool = false, defaultValue: Value? = nil, renamingIdentifier: String? = nil, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        self.name = name
        self.type = type
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.isOptional = isOptional
        self.renamingIdentifier = renamingIdentifier
        self.ingest = ingest
      }


    public func copy(withModifier method: (inout Self) -> Void) -> Self
      {
        var copy = self
        method(&copy)
        return copy
      }
  }


// MARK: --

extension AttributeInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSAttributeDescription.
    public enum Change : Hashable
      {
        case name
        case isOptional
        case type
        //case isTransient(Bool, Bool)
      }

    public func difference(from old: Self) throws -> Set<Change>?
      {
        let changes : [Change] = [
          old.name != self.name ? .name : nil,
          old.isOptional != self.isOptional ? .isOptional : nil,
          old.type != self.type ? .type : nil,
        ].compactMap {$0}
        return changes.count > 0 ? Set(changes) : nil
      }
  }
