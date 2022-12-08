/*

*/

import Foundation


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
    public let ingestInfo: IngestInfo?


    /// Initialize a new instance.
    public init(name: String, arity: Arity, deleteRule: DeleteRule, relatedEntityName: String, inverseName: String, inverseArity: Arity, inverseDeleteRule: DeleteRule, ingestInfo: IngestInfo?)
      {
        self.name = name
        self.arity = arity
        self.deleteRule = deleteRule
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.inverseArity = inverseArity
        self.inverseDeleteRule = inverseDeleteRule
        self.ingestInfo = ingestInfo
      }


    public func inverse(for entityName: String) -> Relationship
      {
        .init(
          name: inverseName,
          arity: inverseArity,
          deleteRule: deleteRule,
          relatedEntityName: entityName,
          inverseName: name,
          inverseArity: arity,
          inverseDeleteRule: deleteRule,
          ingestInfo: nil
        )
      }


    public var ingested : Bool
      { ingestInfo != nil }


    public var optional : Bool
      {
        switch arity {
          case .optionalToOne, .toMany :
            return true
          case .toOne :
            return false
        }
      }


    public func ingest(json: Any) throws -> NSObject
      {
        fatalError()
      }
  }


extension Relationship.Arity
  {
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
