/*

*/

import CoreData


@propertyWrapper
public struct Relationship<Value> : ManagedPropertyWrapper
  {
    public let managedProperty : ManagedProperty


    // MARK: - to-one -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil) where Value : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .toOne, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestMode m: ManagedRelationship.IngestMode, ingestKey k: IngestKey? = nil) where Value : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .toOne, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-optional -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil) where Value : Nullable, Value.Wrapped : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .optionalToOne, relatedEntityName: Value.Wrapped.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestMode m: ManagedRelationship.IngestMode, ingestKey k: IngestKey? = nil) where Value : Nullable, Value.Wrapped : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .optionalToOne, relatedEntityName: Value.Wrapped.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-many -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil) where Value : SetAlgebra & ExpressibleByArrayLiteral, Value.Element : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .toMany, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestMode m: ManagedRelationship.IngestMode, ingestKey k: IngestKey? = nil) where Value : SetAlgebra & ExpressibleByArrayLiteral, Value.Element : ManagedObject
      {
        managedProperty = ManagedRelationship(name, arity: .toMany, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - enclosing self -

    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let wrapper = instance[keyPath: storageKeyPath]
          let storedValue = instance.value(forKey: wrapper.managedProperty.name)
          guard let value = storedValue as? Value else {
            fatalError("failed to interpret \(String(describing: storedValue)) as \(Value.self)")
          }
          return value
        }
        set {
          let wrapper = instance[keyPath: storageKeyPath]
          instance.setValue(newValue, forKey: wrapper.managedProperty.name)
        }
      }


    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
