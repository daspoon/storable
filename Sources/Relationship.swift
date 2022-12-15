/*

*/

import CoreData


/// Represents a relation between entities.  Note that every relationship has an inverse, but only one endpoint is specified explicitly.
public struct Relationship : Property
  {
    public enum Arity : String, Ingestible { case toOne, optionalToOne, toMany }
    public enum DeleteRule : String, Ingestible { case cascade, nullify }
    public enum IngestMode : String, Ingestible { case reference, create }

    public typealias IngestInfo = (key: IngestKey, mode: IngestMode)

    /// The name of the corresponding property of the source entity.
    public let name : String

    /// The arity indicates the potential number of related objects.
    public let arity : Arity

    /// The name of the related entity.
    public let relatedEntityName : String

    /// The effect which deleting the host object has on the related object.
    public let deleteRule : DeleteRule

    /// The name of the inverse relationship on the destination entity.
    public let inverseName : String

    /// The the arity of the inverse relationship on the destination entity.
    public let inverseArity : Arity

    /// The effect which deleting the related object has on the host object.
    public let inverseDeleteRule : DeleteRule

    /// Determines how related objects are obtained from the ingest value, if any, provided on object initialization: a mode of 'reference' indicates that ingested values name existing objects;
    /// a mode of 'create' indicates ingested values are JSON data used to create the related objects. Nil indicates the relation is not ingested.
    public let ingestKey : IngestKey
    public let ingestMode : IngestMode


    /// Initialize a new instance.
    public init(_ name: String, arity: Arity, relatedEntityName: String, inverseName: String, deleteRule: DeleteRule? = nil, inverseArity: Arity? = nil, inverseDeleteRule: DeleteRule? = nil, ingestKey: IngestKey? = nil, ingestMode: IngestMode? = nil)
      {
        self.name = name
        self.arity = arity
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.deleteRule = deleteRule ?? .defaultValue(for: arity)
        self.inverseArity = inverseArity ?? .defaultInverseValue(for: arity)
        self.inverseDeleteRule = inverseDeleteRule ?? .defaultInverseValue(for: arity)
        self.ingestKey = ingestKey ?? .element(name)
        self.ingestMode = ingestMode ?? .defaultValue(for: arity)
      }


    public func inverse(for entityName: String) -> Relationship
      {
        Self(inverseName,
          arity: inverseArity,
          relatedEntityName: entityName,
          inverseName: name,
          deleteRule: deleteRule,
          inverseArity: arity,
          inverseDeleteRule: deleteRule,
          ingestKey: .ignore,
          ingestMode: .reference
        )
      }


    public var defaultIngestValue : (any Storable)?
      { nil }


    public var allowsNilValue : Bool
      {
        switch arity {
          case .optionalToOne, .toMany :
            return true
          case .toOne :
            return false
        }
      }
  }


// MARK: --

extension Relationship.Arity
  {
    public static func defaultInverseValue(for arity: Relationship.Arity) -> Self
      {
        switch arity {
          case .toOne : return .toMany
          case .toMany : return .toOne
          case .optionalToOne : return .optionalToOne
        }
      }

    var rangeOfCount : ClosedRange<Int>
      {
        switch self {
          case .optionalToOne :
            return 0 ... 1
          case .toOne :
            return 1 ... 1
          case .toMany :
            return 0 ... .max
        }
      }
  }


// MARK: --

extension Relationship.DeleteRule
  {
    public static func defaultValue(for arity: Relationship.Arity) -> Self
      {
        switch arity {
          case .toOne, .optionalToOne : return .nullify
          case .toMany : return .cascade
        }
      }

    public static func defaultInverseValue(for arity: Relationship.Arity) -> Self
      {
        switch arity {
          case .toOne : return .cascade
          case .toMany, .optionalToOne : return .nullify
        }
      }
  }


// MARK: --

extension Relationship.IngestMode
  {
    public static func defaultValue(for arity: Relationship.Arity) -> Self
      {
        switch arity {
          case .toOne, .optionalToOne : return .reference
          case .toMany : return .create
        }
      }
  }
