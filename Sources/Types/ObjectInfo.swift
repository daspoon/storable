/*

*/

import CoreData


/// ObjectInfo is conceptually equivalent to NSEntityDescription, but maintains additional data required to perform object ingestion.

public struct ObjectInfo
  {
    public let name : String
    public private(set) var attributes : [String: AttributeInfo] = [:]
    public private(set) var relationships : [String: RelationshipInfo] = [:]
    public private(set) var fetchedProperties : [String: FetchedPropertyInfo] = [:]
    public let managedObjectClass : Object.Type


    /// Create a new instance for the given subclass of Object.
    public init(objectType: Object.Type) throws
      {
        name = objectType.entityNameAndVersion.entityName
        managedObjectClass = objectType

        // Skip the base class Object since it has no properties, and attempting to create a mirror crashes...
        guard objectType != Object.self else { return }

        for (label, value) in objectType.instanceMirror.children {
          guard let label, label.hasPrefix("_") else { continue }
          guard let info = (value as? ManagedProperty)?.propertyInfo else { continue }
          let propertyName = label.removing(prefix: "_")
          guard info.name == propertyName else {
            throw Exception("declared property name must match wrapper argument")
          }
          switch info {
            case let attribute as AttributeInfo :
              attributes[propertyName] = attribute
            case let relationship as RelationshipInfo :
              relationships[propertyName] = relationship
            case let fetchedProperty as FetchedPropertyInfo :
              fetchedProperties[propertyName] = fetchedProperty
            default :
              log("unsupported PropertyInfo type: \(type(of: info))")
          }
        }
      }


    public var previousName : String?
      { managedObjectClass.previousEntityName }
  }


extension ObjectInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSEntityDescription.
    public enum DescriptorChange : CaseIterable, Equatable
      {
        case name
        case isAbstract
        //case versionHashModifier

        func didChange(from old: ObjectInfo, to new: ObjectInfo) -> Bool
          {
            switch self {
              case .name : return new.name != old.name
              case .isAbstract : return new.managedObjectClass.isAbstract != old.managedObjectClass.isAbstract
              //case .versionHashModifier : return new.versionHashModifier != old.versionHashModifier
            }
          }
      }

    /// The difference between two ObjectInfo instances combines the changes to the entity description with the differences between attributes/relationships.
    public struct Difference : Equatable
      {
        public let descriptorChanges : Set<DescriptorChange>
        public let attributesDifference : Dictionary<String, AttributeInfo>.Difference
        public let relationshipsDifference : Dictionary<String, RelationshipInfo>.Difference

        public init?(descriptorChanges: Set<DescriptorChange> = [], attributesDifference: Dictionary<String, AttributeInfo>.Difference? = nil, relationshipsDifference : Dictionary<String, RelationshipInfo>.Difference? = nil)
          {
            guard !(descriptorChanges.isEmpty && (attributesDifference ?? .empty).isEmpty && (relationshipsDifference ?? .empty).isEmpty) else { return nil }
            self.descriptorChanges = descriptorChanges
            self.attributesDifference = attributesDifference ?? .empty
            self.relationshipsDifference = relationshipsDifference ?? .empty
          }
      }

    /// Return the difference between the receiver and its prior version.
    public func difference(from old: Self) throws -> Difference?
      {
        return Difference(
          descriptorChanges: Set(DescriptorChange.allCases.compactMap { $0.didChange(from: old, to: self) ? $0 : nil }),
          attributesDifference: try attributes.difference(from: old.attributes, moduloRenaming: \.previousName),
          relationshipsDifference: try relationships.difference(from: old.relationships, moduloRenaming: \.previousName)
        )
      }
  }
