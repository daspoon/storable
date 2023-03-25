/*

  Created by David Spooner

*/

import CoreData


/// The Relationship struct defines a relationship on a class of managed object; it is analogous to CoreData's NSRelationshipDescription.

public struct Relationship
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


    /// Initialize a new instance.
    public init(name: String, range: ClosedRange<Int>, relatedEntityName: String, inverse: InverseSpec, deleteRule: DeleteRule)
      {
        precondition(range.lowerBound >= 0 && range.upperBound >= 1)

        self.name = name
        self.range = range
        self.relatedEntityName = relatedEntityName
        self.inverse = inverse
        self.deleteRule = deleteRule
      }


    /// Declare a to-one relationship.
    public init<T: ManagedObject>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule)
      { self.init(name: name, range: 1 ... 1, relatedEntityName: T.entityName, inverse: inv, deleteRule: r) }

    /// Declare a to-optional relationship.
    public init<T: Nullable>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule) where T.Wrapped : ManagedObject
      { self.init(name: name, range: 0 ... 1, relatedEntityName: T.Wrapped.entityName, inverse: inv, deleteRule: r) }

    /// Declare a to-many relationship.
    public init<T: SetAlgebra>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule) where T.Element : ManagedObject
      { self.init(name: name, range: 0 ... .max, relatedEntityName: T.Element.entityName, inverse: inv, deleteRule: r) }


    /// Return a descriptor for the inverse relationship if possible.
    func inverse(toEntityName thisEntityName: String) -> Self?
      {
        guard let detail = inverse.detail else { return nil }
        return Self(name: inverse.name, range: detail.range, relatedEntityName: thisEntityName, inverse: .init(stringLiteral: relatedEntityName), deleteRule: detail.deleteRule)
      }
  }


// MARK: --

/// The Relationship macro, when applied to member variables of an ManagedObject subclass, generates instances of the Relationship struct.

@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")


// MARK: --

extension Relationship.InverseSpec : ExpressibleByStringLiteral
  {
    /// Used to indicate the inverse relationship is explicitly declared by the related entity. In this case only the inverse name is required.
    public init(stringLiteral name: String)
      { self.name = name }

    /// Used to indicate the inverse relationship is not declared by the related entity; in this case all necessary information must be spectified.
    public init(name: String, range: ClosedRange<Int>, deleteRule: Relationship.DeleteRule, renamingIdentifier: String? = nil)
      {
        self.name = name
        self.detail = (range, deleteRule, renamingIdentifier)
      }
  }
