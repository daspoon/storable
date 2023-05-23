/*

  Created by David Spooner

*/

import CoreData


/// The Attribute struct maintains defines an attribute on a class of managed object; it is analogous to CoreData's NSAttributeDescription.

public struct Attribute
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
    public var defaultValue : Any?

    /// Indicates whether or not nil is an legitimate property value.
    public var isOptional : Bool

    /// The name of the attribute in the previous entity version, if necessary.
    public var renamingIdentifier : String?

    /// Determines how values are extracted from object ingest data.
    public var ingestKey : IngestKey

    /// Type-aware methods for importing/exporting attribute values.
    private let decodeMethod : (inout KeyedDecodingContainer<NameCodingKey>) throws -> Any?
    private let encodeMethod : (Any, inout KeyedEncodingContainer<NameCodingKey>) throws -> Void


    /// Initialize a new instance.
    private init<T: Codable>(
        name: String,
        type: T.Type,
        attributeType: NSAttributeDescription.AttributeType,
        isOptional: Bool = false,
        valueTransformerName: NSValueTransformerName? = nil,
        defaultValue: Any? = nil,
        renamingIdentifier: String? = nil,
        ingestKey: IngestKey? = nil
      )
      {
        self.name = name
        self.type = type
        self.attributeType = attributeType
        self.valueTransformerName = valueTransformerName
        self.defaultValue = defaultValue
        self.isOptional = isOptional
        self.renamingIdentifier = renamingIdentifier
        self.ingestKey = ingestKey ?? .element(name)

        decodeMethod = { container in try container.decodeIfPresent(T.self, forKey: .init(name: name)) }
        encodeMethod = { value, container in try container.encode(value as! T, forKey: .init(name: name)) }
      }


    /// Declare a non-optional standard attribute.
    public init<T: StorageType>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil)
      { self.init(name: name, type: t, attributeType: T.typeId, valueTransformerName: T.valueTransformerName, defaultValue: v, renamingIdentifier: id, ingestKey: k) }


    /// Declare a non-optional storable attribute.
    public init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil)
      { self.init(name: name, type: t, attributeType: T.EncodingType.typeId, valueTransformerName: T.valueTransformerName, defaultValue: v?.storedValue(), renamingIdentifier: id, ingestKey: k) }


    /// Declare an optional standard attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil) where T.Wrapped : StorageType
      { self.init(name: name, type: T.Wrapped.self, attributeType: T.Wrapped.typeId, isOptional: true, valueTransformerName: T.Wrapped.valueTransformerName, defaultValue: v, renamingIdentifier: id, ingestKey: k) }


    /// Declare an optional storable attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil) where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, attributeType: T.Wrapped.EncodingType.typeId, isOptional: true, valueTransformerName: T.Wrapped.valueTransformerName, defaultValue: v?.storedValue(), renamingIdentifier: id, ingestKey: k) }


    /// Return a copy of the receiver with changes made by the given code block.
    public func copy(withModifier method: (inout Self) -> Void) -> Self
      {
        var copy = self
        method(&copy)
        return copy
      }


    func decodeValue(from container: inout KeyedDecodingContainer<NameCodingKey>) throws -> Any?
      { try decodeMethod(&container) }

    func encodeValue(_ value: Any, to container: inout KeyedEncodingContainer<NameCodingKey>) throws
      { try encodeMethod(value, &container) }
  }


// MARK: --

extension Attribute : Diffable
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
