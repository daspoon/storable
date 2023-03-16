/*

  Created by David Spooner

*/

import CoreData


/// AttributeInfo maintains the metadata for a managed attribute of an Entity class; it is analogous to CoreData's NSAttributeDescription.

public struct AttributeInfo
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


    /// Initialize a new instance.
    private init<Value: Storable>(name: String, type: Value.Type, isOptional: Bool, defaultValue: Value?, renamingIdentifier: String?, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
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


    /// Declare a non-optional attribute.
    public init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v, renamingIdentifier: id) }

    /// Declare a non-optional attribute which is ingestible.
    public init<T: Storable&Ingestible>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v, renamingIdentifier: id, ingest: (.element(name), T.ingest)) }

    /// Declare a non-optional attribute which is ingestible using the specified key.
    public init<T: Storable&Ingestible>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v, renamingIdentifier: id, ingest: (k, T.ingest)) }

    /// Declare an attribute which is transformed from an alternate format on ingestion. If a default value is provided, it must be of the input type of the given transform.
    public init<T: Storable&Ingestible, Alt>(name: String, type t: T.Type, defaultValue v: Alt? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil, transform f: @escaping (Alt) throws -> T.Input)
      {
        // Transform the given default value.
        let u = v.map {try! T.ingest($0, withTransform: f)}
        self.init(name: name, type: t, isOptional: false, defaultValue: u, renamingIdentifier: id, ingest: (k ?? .element(name), {try T.ingest($0, withTransform: f)}))
      }


    /// Declare an optional attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil) where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v, renamingIdentifier: id) }

    /// Declare an optional attribute which is ingestible.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil) where T.Wrapped : Storable&Ingestible
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v, renamingIdentifier: id, ingest: (.element(name), T.Wrapped.ingest)) }

    /// Declare an optional attribute which is ingestible using the specified key.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey) where T.Wrapped : Storable&Ingestible
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v, renamingIdentifier: id, ingest: (k, T.Wrapped.ingest)) }

    /// Declare an optional attribute which is transformed from an alternate format on ingestion.
    public init<T: Nullable, Alt>(name: String, type t: T.Type, defaultValue v: Alt? = nil, renamingIdentifier id: String? = nil, ingestKey k: IngestKey? = nil, transform f: @escaping (Alt) throws -> T.Wrapped.Input) where T.Wrapped : Storable&Ingestible
      {
        // Transform the given default value.
        let u = v.map {try! T.Wrapped.ingest($0, withTransform: f)}
        self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: u, renamingIdentifier: id, ingest: (k ?? .element(name), {try T.Wrapped.ingest($0, withTransform: f)}))
      }


    /// Return a copy of the receiver with changes made by the given code block.
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
