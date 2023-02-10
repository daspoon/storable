/*

*/

import CoreData


/// Relationship is a property wrapper used to declared managed relationships on subclasses of Object.

@propertyWrapper
public struct Relationship<Value> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo


    // MARK: - to-one -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-optional -

    public init<T: Object>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value == T?
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... 1, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    public init<T: Object>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value == T?
      {
        propertyInfo = RelationshipInfo(name, arity:  0 ... 1, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-many -

    public init<T: Object>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil) where Value == Set<T>
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... .max, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName)
      }

    public init<T: Object>(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, renamingIdentifier oldName: String? = nil, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value == Set<T>
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... .max, relatedEntityName: T.entityName, inverseName: inverseName, deleteRule: r, renamingIdentifier: oldName, ingest: (key: k ?? .element(name), mode: m))
      }


    /// The enclosing-self subscript which implements access and update of the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let wrapper = instance[keyPath: storageKeyPath]
          let storedValue = instance.value(forKey: wrapper.propertyInfo.name)
          guard let value = storedValue as? Value else {
            fatalError("failed to interpret \(String(describing: storedValue)) as \(Value.self)")
          }
          return value
        }
        set {
          let wrapper = instance[keyPath: storageKeyPath]
          instance.setValue(newValue, forKey: wrapper.propertyInfo.name)
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
