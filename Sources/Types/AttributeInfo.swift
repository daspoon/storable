/*

*/

import CoreData


/// AttributeInfo represents an managed attribute declared via the Attribute property wrapper. It is essentially an enhancement of NSAttributeDescription which maintains additional data required for object ingestion.

public struct AttributeInfo : PropertyInfo
  {
    /// The managed property name.
    public let name : String

    /// The Storable value type provided on initialization.
    public let type : Any.Type

    /// The CoreData attribute storage type..
    public let attributeType : NSAttributeDescription.AttributeType

    /// Non-nil when attributeType is 'transformable'
    public let valueTransformerName : NSValueTransformerName?

    /// The optional default value.
    public let defaultValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public let allowsNilValue : Bool

    /// If non-nil, determines how json values are extracted from object ingest data and transformed to stored values.
    public let ingest : (key: IngestKey, method: (Any) throws -> any Storable)?


    public init<Value: Storable>(name: String, type: Value.Type, defaultValue: Value? = nil, ingest: (key: IngestKey, method: (Any) throws -> any Storable)? = nil)
      {
        self.name = name
        self.type = type
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.allowsNilValue = Value.EncodingType.isOptional
        self.ingest = ingest
      }
  }


// MARK: --

extension AttributeInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSAttributeDescription.
    public enum Change : CaseIterable
      {
        case name
        case isOptional
        //case isTransient
        case type
        //case versionHashModifier

        func didChange(from old: AttributeInfo, to new: AttributeInfo) -> Bool
          {
            switch self {
              case .name : return new.name != old.name
              case .isOptional : return new.allowsNilValue != old.allowsNilValue
              //case .isTransient : return new.isTransient != old.isTransient
              case .type : return new.type != old.type
              //case .versionHashModifier : return new.versionHashModifier != old.versionHashModifier
            }
          }
      }

    /// Return the list of changes from a previous version.
    public func difference(from old: Self) -> [Change]?
      { Change.allCases.compactMap { $0.didChange(from: old, to: self) ? $0 : nil } }
  }
