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
    public let name : String

    /// The arity indicates the potential number of related objects.
    public let arity : ClosedRange<Int>

    /// The name of the related entity.
    public let relatedEntityName : String

    /// The effect which deleting the host object has on the related object.
    public let deleteRule : NSDeleteRule

    /// The name of the inverse relationship on the destination entity.
    public let inverseName : String

    /// Indicates how values are established on object ingestion.
    public let ingest : (key: IngestKey, mode: IngestMode)?


    /// Initialize a new instance.
    public init(_ name: String, arity: ClosedRange<Int>, relatedEntityName: String, inverseName: String, deleteRule: NSDeleteRule, ingest: (key: IngestKey, mode: IngestMode)? = nil)
      {
        precondition(arity.lowerBound >= 0 && arity.upperBound >= 1)

        self.name = name
        self.arity = arity
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.deleteRule = deleteRule
        self.ingest = ingest
      }
  }
