/*

  Created by David Spooner

*/

import CoreData


/// EntityInfo maintains the metadata for a subclass of Entity; it is analogous to CoreData's NSEntityDescription.

public struct EntityInfo
  {
    public let name : String
    public private(set) var attributes : [String: AttributeInfo] = [:]
    public private(set) var relationships : [String: RelationshipInfo] = [:]
    public private(set) var fetchedProperties : [String: FetchedPropertyInfo] = [:]
    public let managedObjectClass : Entity.Type


    /// Create a new instance for the given subclass of Entity.
    public init(objectType: Entity.Type) throws
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


    mutating func addAttribute(_ attribute: AttributeInfo)
      {
        assert(attributes[attribute.name] == nil && relationships[attribute.name] == nil && fetchedProperties[attribute.name] == nil)
        attributes[attribute.name] = attribute
      }

    mutating func addRelationship(_ relationship: RelationshipInfo)
      {
        assert(attributes[relationship.name] == nil && relationships[relationship.name] == nil && fetchedProperties[relationship.name] == nil)
        relationships[relationship.name] = relationship
      }

    mutating func removeAttributeNamed(_ name: String)
      {
        attributes.removeValue(forKey: name)
      }


    mutating func withAttributeNamed(_ name: String, update: (inout AttributeInfo) -> Void)
      { update(&attributes[name]!) }

    mutating func withRelationshipNamed(_ name: String, update: (inout RelationshipInfo) -> Void)
      { update(&relationships[name]!) }
  }


extension EntityInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSEntityDescription.
    public enum DescriptorChange : Hashable
      {
        case name
        case isAbstract
      }

    /// The difference between two EntityInfo instances combines the changes to the entity-specific state with the differences between attributes and relationships.
    public struct Difference : Equatable
      {
        public let descriptorChanges : Set<DescriptorChange>
        public let attributesDifference : Dictionary<String, AttributeInfo>.Difference
        public let relationshipsDifference : Dictionary<String, RelationshipInfo>.Difference

        public init?(descriptorChanges: [DescriptorChange] = [], attributesDifference: Dictionary<String, AttributeInfo>.Difference? = nil, relationshipsDifference: Dictionary<String, RelationshipInfo>.Difference? = nil)
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
