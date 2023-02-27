/*

*/

import CoreData


/// RelationshipInfo represents an managed relationship declared via the Relationship property wrapper. It is essentially an enhancement of NSDescriptionDescription which maintains additional data required for object ingestion.

public struct RelationshipInfo : PropertyInfo
  {
    /// Determines how related objects are obtained from object ingest data.
    public enum IngestMode : String
      {
        /// Ingested values are the names of existing objects.
        case reference
        /// Ingested values are the data required to construct related objects.
        case create
      }

    /// The name of the corresponding property of the source entity.
    public var name : String

    /// The arity indicates the potential number of related objects.
    public var arity : ClosedRange<Int>

    /// The name of the related entity.
    public var relatedEntityName : String

    /// The name of the inverse relationship on the destination entity.
    public var inverseName : String

    /// The effect which deleting the host object has on the related object.
    public var deleteRule : NSDeleteRule

    /// The name of the relationship in the previous entity version, if necessary.
    public var renamingIdentifier : String?

    /// Indicates how values are established on object ingestion.
    public var ingest : (key: IngestKey, mode: IngestMode)?


    /// Initialize a new instance.
    public init(_ name: String, arity: ClosedRange<Int>, relatedEntityName: String, inverseName: String, deleteRule: NSDeleteRule, renamingIdentifier: String? = nil, ingest: (key: IngestKey, mode: IngestMode)? = nil)
      {
        precondition(arity.lowerBound >= 0 && arity.upperBound >= 1)

        self.name = name
        self.arity = arity
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.deleteRule = deleteRule
        self.renamingIdentifier = renamingIdentifier
        self.ingest = ingest
      }
  }


// MARK: --

extension RelationshipInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSRelationshipDescription.
    public enum Change : Hashable
      {
        case name
        case relatedEntityName
        case inverseName
        //case isOrdered
        //case isTransient
        case rangeOfCount
      }

    public func difference(from old: Self) throws -> Set<Change>?
      {
        let changes : [Change] = [
          old.name != self.name ? .name : nil,
          old.relatedEntityName != self.relatedEntityName ? .relatedEntityName : nil,
          old.inverseName != self.inverseName ? .inverseName : nil,
          old.arity != self.arity ? .rangeOfCount : nil,
        ].compactMap {$0}
        return changes.count > 0 ? Set(changes) : nil
      }
  }
