/*

*/

import CoreData


/// Represents a relation between entities.  Note that every relationship has an inverse, but only one endpoint is specified explicitly.
public struct ManagedRelationship : ManagedProperty
  {
    public enum Arity : String, Ingestible { case toOne, optionalToOne, toMany }
    public enum IngestMode : String, Ingestible { case reference, create }
    public typealias DeleteRule = NSDeleteRule

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

    /// Indicates how values are established on object ingestion.
    public let ingestKey : IngestKey

    /// Determines how related objects are obtained from the ingest value, if any, provided on object initialization: a mode of 'reference' indicates that ingested values name existing objects;
    /// a mode of 'create' indicates ingested values are JSON data used to create the related objects. Nil indicates the relation is not ingested.
    public let ingestMode : IngestMode


    /// Initialize a new instance.
    public init(_ name: String, arity: Arity, relatedEntityName: String, inverseName: String, deleteRule: DeleteRule? = nil, ingestKey: IngestKey? = nil, ingestMode: IngestMode? = nil)
      {
        self.name = name
        self.arity = arity
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.deleteRule = deleteRule ?? .defaultValue(for: arity)
        self.ingestKey = ingestKey ?? .element(name)
        self.ingestMode = ingestMode ?? .defaultValue(for: arity)
      }


    public func inverse(for entityName: String) -> ManagedRelationship
      {
        Self(inverseName,
          arity: .defaultInverseValue(for: arity),
          relatedEntityName: entityName,
          inverseName: name,
          deleteRule: .defaultInverseValue(for: arity),
          ingestKey: .ignore,
          ingestMode: .reference
        )
      }
  }


// MARK: --

extension ManagedRelationship.Arity
  {
    public static func defaultInverseValue(for arity: ManagedRelationship.Arity) -> Self
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

extension ManagedRelationship.DeleteRule
  {
    public static func defaultValue(for arity: ManagedRelationship.Arity) -> Self
      {
        switch arity {
          case .toOne, .optionalToOne : return .nullifyDeleteRule
          case .toMany : return .cascadeDeleteRule
        }
      }

    public static func defaultInverseValue(for arity: ManagedRelationship.Arity) -> Self
      {
        switch arity {
          case .toOne : return .cascadeDeleteRule
          case .toMany, .optionalToOne : return .nullifyDeleteRule
        }
      }
  }


// MARK: --

extension ManagedRelationship.IngestMode
  {
    public static func defaultValue(for arity: ManagedRelationship.Arity) -> Self
      {
        switch arity {
          case .toOne, .optionalToOne : return .reference
          case .toMany : return .create
        }
      }
  }
