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
  }


extension ObjectInfo : Diffable
  {
    /// Changes which affect the version hash of the generated NSEntityDescription.
    public enum DescriptorChange : CaseIterable
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
    public struct Difference
      {
        public let descriptorChanges : [DescriptorChange]
        public let attributesDifference : Dictionary<String, AttributeInfo>.Difference?
        public let relationshipsDifference : Dictionary<String, RelationshipInfo>.Difference?

        init?(from old: ObjectInfo, to new: ObjectInfo)
          {
            descriptorChanges = DescriptorChange.allCases.compactMap { $0.didChange(from: old, to: new) ? $0 : nil }
            attributesDifference = Self.propertiesDifference(from: old.attributes, to: new.attributes)
            relationshipsDifference = Self.propertiesDifference(from: old.relationships, to: new.relationships)

            guard !(descriptorChanges.isEmpty && attributesDifference == nil && relationshipsDifference == nil) else { return nil }
          }

        static func propertiesDifference<T: PropertyInfo & Diffable>(from sourceProperties: [String: T], to targetProperties: [String: T]) -> Dictionary<String, T>.Difference?
          {
            // NOTE: it is expected that the properties dictionaries belong to (entities of) a Schema (the target) and its predecessor (the source),
            // and that Schema initialization has enforced the following restrictions on (non-nil) property renaming:
            //   1) the specified name differs from the property name
            //   2) the previous model has a same-kinded property of the specified name
            //   3) each source property has at most one corresponding target property

            var difference = Dictionary<String, T>.Difference()

            // The removed properties are the source properties without a corresponding target property, as determined by the following procedure...
            difference.removed = sourceProperties

            // Enumerate the target properties to determine (modulo renaming) whether or not they correspond to source properties: if so, account for modification and mark as having a correspondent; otherwise, the property must be newly added.
            for (targetName, targetProperty) in targetProperties {
              if let sourceProperty = sourceProperties[targetProperty.previousName ?? targetName] {
                precondition(difference.removed[sourceProperty.name] != nil)
                if let delta = targetProperty.difference(from: sourceProperty) {
                  difference.modified[targetName] = delta
                }
                difference.removed.removeValue(forKey: sourceProperty.name)
              }
              else {
                precondition(targetProperty.previousName == nil)
                difference.added[targetName] = targetProperty
              }
            }

            return difference
          }
      }

    /// Return the list of changes from the given prior definition.
    public func difference(from old: Self) -> Difference?
      { Difference(from: old, to: self) }
  }
