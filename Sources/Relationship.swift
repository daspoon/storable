/*

*/

import CoreData


@propertyWrapper
public struct Relationship<Value> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo


    // MARK: - to-one -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule) where Value : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 1 ... 1, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-optional -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule) where Value : Nullable, Value.Element : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... 1, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value : Nullable, Value.Element : Object
      {
        propertyInfo = RelationshipInfo(name, arity:  0 ... 1, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - to-many -

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule) where Value : SetAlgebra, Value.Element : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... .max, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r)
      }

    public init(_ name: String, inverseName: String, deleteRule r: NSDeleteRule, ingestMode m: RelationshipInfo.IngestMode, ingestKey k: IngestKey? = nil) where Value : SetAlgebra, Value.Element : Object
      {
        propertyInfo = RelationshipInfo(name, arity: 0 ... .max, relatedEntityName: Value.Element.entityName, inverseName: inverseName, deleteRule: r, ingest: (key: k ?? .element(name), mode: m))
      }


    // MARK: - enclosing self -

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


    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
