/*

  Created by David Spooner

*/

import CoreData


/// RelationshipInfo maintains the metadata for a relationship defined of an Entity class; it is analogous to CoreData's NSRelationshipDescription.

public struct RelationshipInfo
  {
    /// Determines the effect on related objects when the source object is deleted; this type corresponds directly to NSDeleteRule.
    public enum DeleteRule
      { case noAction, nullify, cascade, deny }

    /// A partial specification of an associated inverse relationship. If details is specified then the related class must not declare the inverse relationship.
    public struct InverseSpec
      {
        var name : String
        var detail : (range: ClosedRange<Int>, deleteRule: DeleteRule, renamingIdentifier: String?)?
      }

    /// Determines how related objects are obtained from object ingest data.
    public enum IngestMode
      {
        /// Ingested values are the names of existing objects.
        case reference
        /// Ingested values are the data required to construct related objects.
        case create(IngestFormat = .dictionary)
      }

    /// The name of the corresponding property of the source entity.
    public var name : String

    /// The range indicates the potential number of related objects.
    public var range : ClosedRange<Int>

    /// The name of the related entity.
    public var relatedEntityName : String

    /// The details of the inverse relationship on the destination entity.
    public var inverse : InverseSpec

    /// The effect which deleting the host object has on the related object.
    public var deleteRule : DeleteRule

    /// The name of the relationship in the previous entity version, if necessary.
    public var renamingIdentifier : String?

    /// Indicates how values are established on object ingestion.
    public var ingest : (key: IngestKey, mode: IngestMode)?


    /// Initialize a new instance.
    public init(name: String, range: ClosedRange<Int>, relatedEntityName: String, inverse: InverseSpec, deleteRule: DeleteRule, renamingIdentifier: String? = nil, ingest: (key: IngestKey, mode: IngestMode)? = nil)
      {
        precondition(range.lowerBound >= 0 && range.upperBound >= 1)

        self.name = name
        self.range = range
        self.relatedEntityName = relatedEntityName
        self.inverse = inverse
        self.deleteRule = deleteRule
        self.renamingIdentifier = renamingIdentifier
        self.ingest = ingest
      }


    /// Declare a to-one relationship.
    public init<T: Entity>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil)
      { self.init(name: name, range: 1 ... 1, relatedEntityName: T.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName) }

    /// Declare a to-optional relationship.
    public init<T: Nullable>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil) where T.Wrapped : Entity
      { self.init(name: name, range: 0 ... 1, relatedEntityName: T.Wrapped.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName) }

    /// Declare a to-many relationship.
    public init<T: SetAlgebra>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil) where T.Element : Entity
      { self.init(name: name, range: 0 ... .max, relatedEntityName: T.Element.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName) }


    /// Declare a to-optional relationship which is ingestible.
    public init<T: Entity>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil)
      { self.init(name: name, range: 1 ... 1, relatedEntityName: T.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m)) }

    /// Declare a to-optional relationship which is ingestible.
    public init<T: Nullable>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where T.Wrapped : Entity
      { self.init(name: name, range:  0 ... 1, relatedEntityName: T.Wrapped.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m)) }

    /// Declare a to-many relationship which is ingestible.
    public init<T: SetAlgebra>(name: String, type: T.Type, inverse inv: RelationshipInfo.InverseSpec, deleteRule r: RelationshipInfo.DeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where T.Element : Entity
      { self.init(name: name, range: 0 ... .max, relatedEntityName: T.Element.entityName, inverse: inv, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m)) }


    /// Return a descriptor for the inverse relationship if possible.
    func inverse(toEntityName thisEntityName: String) -> Self?
      {
        guard let detail = inverse.detail else { return nil }
        return Self(name: inverse.name, range: detail.range, relatedEntityName: thisEntityName, inverse: .init(stringLiteral: relatedEntityName), deleteRule: detail.deleteRule, renamingIdentifier: detail.renamingIdentifier)
      }
  }


extension RelationshipInfo.InverseSpec : ExpressibleByStringLiteral
  {
    /// Used to indicate the inverse relationship is explicitly declared by the related entity. In this case only the inverse name is required.
    public init(stringLiteral name: String)
      { self.name = name }

    /// Used to indicate the inverse relationship is not declared by the related entity; in this case all necessary information must be spectified.
    public init(name: String, range: ClosedRange<Int>, deleteRule: RelationshipInfo.DeleteRule, renamingIdentifier: String? = nil)
      {
        self.name = name
        self.detail = (range, deleteRule, renamingIdentifier)
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
          old.inverse.name != self.inverse.name ? .inverseName : nil,
          old.range != self.range ? .rangeOfCount : nil,
        ].compactMap {$0}
        return changes.count > 0 ? Set(changes) : nil
      }
  }
