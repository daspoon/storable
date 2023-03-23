/*

  Created by David Spooner

*/

import CoreData


/// Entity maintains the metadata for a subclass of ManagedObject; it is analogous to CoreData's NSEntityDescription.

public struct Entity
  {
    public let name : String
    public private(set) var attributes : [String: Attribute] = [:]
    public private(set) var relationships : [String: Relationship] = [:]
    public private(set) var fetchedProperties : [String: Fetched] = [:]
    public let managedObjectClass : ManagedObject.Type


    /// Create a new instance for the given subclass of ManagedObject.
    public init(objectType: ManagedObject.Type) throws
      {
        name = objectType.entityNameAndVersion.entityName
        managedObjectClass = objectType

        for (name, info) in objectType.declaredPropertyInfoByName {
          switch info {
            case .attribute(let info) :
              attributes[name] = info
            case .relationship(let info) :
              relationships[name] = info
            case .fetched(let info) :
              fetchedProperties[name] = info
          }
        }
      }


    public var isAbstract : Bool
      { managedObjectClass.isAbstract }


    public var renamingIdentifier : String?
      { managedObjectClass.renamingIdentifier }


    mutating func addAttribute(_ attribute: Attribute)
      {
        assert(attributes[attribute.name] == nil && relationships[attribute.name] == nil && fetchedProperties[attribute.name] == nil)
        attributes[attribute.name] = attribute
      }

    mutating func addRelationship(_ relationship: Relationship)
      {
        assert(attributes[relationship.name] == nil && relationships[relationship.name] == nil && fetchedProperties[relationship.name] == nil)
        relationships[relationship.name] = relationship
      }

    mutating func removeAttributeNamed(_ name: String)
      {
        attributes.removeValue(forKey: name)
      }


    mutating func withAttributeNamed(_ name: String, update: (inout Attribute) -> Void)
      { update(&attributes[name]!) }

    mutating func withRelationshipNamed(_ name: String, update: (inout Relationship) -> Void)
      { update(&relationships[name]!) }
  }


extension Entity : Diffable
  {
    /// Changes which affect the version hash of the generated NSEntityDescription.
    public enum DescriptorChange : Hashable
      {
        case name
        case isAbstract
      }

    /// The difference between two Entity instances combines the changes to the entity-specific state with the differences between attributes and relationships.
    public struct Difference : Equatable
      {
        public let descriptorChanges : Set<DescriptorChange>
        public let attributesDifference : Dictionary<String, Attribute>.Difference
        public let relationshipsDifference : Dictionary<String, Relationship>.Difference

        public init?(descriptorChanges: [DescriptorChange] = [], attributesDifference: Dictionary<String, Attribute>.Difference? = nil, relationshipsDifference: Dictionary<String, Relationship>.Difference? = nil)
          {
            guard !(descriptorChanges.isEmpty && (attributesDifference ?? .empty).isEmpty && (relationshipsDifference ?? .empty).isEmpty) else { return nil }
            self.descriptorChanges = Set(descriptorChanges)
            self.attributesDifference = attributesDifference ?? .empty
            self.relationshipsDifference = relationshipsDifference ?? .empty
          }
      }

    /// Return the difference between the receiver and its prior version.
    public func difference(from old: Self) throws -> Difference?
      {
        let descriptorChanges : [DescriptorChange] = [
          old.name != self.name ? .name : nil,
          old.isAbstract != self.isAbstract ? .isAbstract : nil,
        ].compactMap {$0}

        return Difference(
          descriptorChanges: descriptorChanges,
          attributesDifference: try attributes.difference(from: old.attributes, moduloRenaming: \.renamingIdentifier),
          relationshipsDifference: try relationships.difference(from: old.relationships, moduloRenaming: \.renamingIdentifier)
        )
      }
  }


// MARK: --

/// The ManagedObject macro, when applied to definitions of ManagedObject subclasses, generates instances of the ManagedObject struct.

@attached(member, names: named(declaredPropertyInfoByName))
public macro ManagedObject() = #externalMacro(module: "StorableMacros", type: "EntityMacro")
