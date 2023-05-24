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

    /// Type-aware methods for importing/exporting attribute values.
    private let decodeMethod : (inout KeyedDecodingContainer<NameCodingKey>) throws -> Any?
    private let encodeMethod : (Any, inout KeyedEncodingContainer<NameCodingKey>) throws -> Void


    /// Initialize a new instance.
    private init<T: Storable>(name: String, type: T.Type, isOptional: Bool, defaultValue: Any?, renamingIdentifier: String?)
      {
        self.name = name
        self.type = type
        self.attributeType = T.EncodingType.typeId
        self.valueTransformerName = T.valueTransformerName
        self.defaultValue = defaultValue
        self.isOptional = isOptional
        self.renamingIdentifier = renamingIdentifier

        decodeMethod = { try $0.decodeIfPresent(T.EncodingType.self, forKey: .init(name: name)) }
        encodeMethod = { try $1.encode($0 as! T.EncodingType, forKey: .init(name: name)) }
      }


    /// Declare a non-optional storable attribute.
    public init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v?.storedValue(), renamingIdentifier: id) }


    /// Declare an optional storable attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil) where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v?.storedValue(), renamingIdentifier: id) }


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
