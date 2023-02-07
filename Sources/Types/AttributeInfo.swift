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
    public var allowsNilValue : Bool

    /// The name of the attribute in the previous entity version, if necessary.
    public var previousName : String?

    /// If non-nil, determines how json values are extracted from object ingest data and transformed to stored values.
    public var ingest : (key: IngestKey, method: (Any) throws -> any Storable)?


    public init<Value: Storable>(name: String, type: Value.Type, defaultValue: Value? = nil, previousName: String? = nil, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        self.name = name
        self.type = type
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.allowsNilValue = Value.EncodingType.isOptional
        self.previousName = previousName
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
        case name(String, String)
        case isOptional(Bool, Bool)
        case valueType(Any.Type, Any.Type)
        case storageType(NSAttributeDescription.AttributeType, NSAttributeDescription.AttributeType)
        //case isTransient(Bool, Bool)
        //case versionHashModifier(String, String)
      }

    public func difference(from old: Self) throws -> Set<Change>?
      {
        let changes : [Change] = [
          old.name != self.name ? .name(old.name, self.name) : nil,
          old.allowsNilValue != self.allowsNilValue ? .isOptional(old.allowsNilValue, self.allowsNilValue) : nil,
          old.type != self.type ? .valueType(old.type, self.type) : nil,
          old.attributeType != self.attributeType ? .storageType(old.attributeType, self.attributeType) : nil,
        ].compactMap {$0}
        return changes.count > 0 ? Set(changes) : nil
      }
  }


/// An explicit implementation of Hashable is required because Any.Type is not Hashable.
extension AttributeInfo.Change
  {
    public func hash(into hasher: inout Hasher)
      {
        switch self {
          case .name(let old, let new) : hasher.combine([old, new])
          case .isOptional(let old, let new) : hasher.combine([old, new])
          case .valueType(let old, let new) : hasher.combine([ObjectIdentifier(old), ObjectIdentifier(new)])
          case .storageType(let old, let new) : hasher.combine([old, new])
        }
      }

    public static func == (lhs: Self, rhs: Self) -> Bool
      {
        switch (lhs, rhs) {
          case (.name(let old1, let new1), .name(let old2, let new2)) : return old1 == old2 && new1 == new2
          case (.isOptional(let old1, let new1), .isOptional(let old2, let new2)) : return old1 == old2 && new1 == new2
          case (.valueType(let old1, let new1), .valueType(let old2, let new2)) : return old1 == old2 && new1 == new2
          case (.storageType(let old1, let new1), .storageType(let old2, let new2)) : return old1 == old2 && new1 == new2
          default :
            return false
        }
      }
  }
