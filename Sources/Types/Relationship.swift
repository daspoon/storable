/*

  Created by David Spooner

*/

import CoreData


/// Relationship is a property wrapper used to declared managed relationships on subclasses of Entity.

@propertyWrapper
public struct Relationship<Value> : ManagedPropertyWrapper
  {
    public let propertyInfo : PropertyInfo


    /// Declare a to-one relationship.
    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value : Entity
      {
        propertyInfo = RelationshipInfo(name, range: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    /// Declare a to-one relationship.
    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value : Entity
      {
        propertyInfo = RelationshipInfo(name, range: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }

    /// Declare a to-optional relationship.
    public init<T: Entity>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value == T?
      {
        propertyInfo = RelationshipInfo(name, range: 0 ... 1, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    /// Declare a to-optional relationship which is ingestible.
    public init<T: Entity>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value == T?
      {
        propertyInfo = RelationshipInfo(name, range:  0 ... 1, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }

    /// Declare a to-many relationship.
    public init<T: Entity>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value == Set<T>
      {
        propertyInfo = RelationshipInfo(name, range: 0 ... .max, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    /// Declare a to-many relationship which is ingestible.
    public init<T: Entity>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value == Set<T>
      {
        propertyInfo = RelationshipInfo(name, range: 0 ... .max, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }


    /// The enclosing-self subscript which implements access and update of the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          let storedValue = instance.value(forKey: propertyInfo.name)
          guard let value = storedValue as? Value
            else { fatalError("failed to interpret \(String(describing: storedValue)) as \(Value.self)") }
          return value
        }
        set {
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          instance.setValue(newValue, forKey: propertyInfo.name)
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
