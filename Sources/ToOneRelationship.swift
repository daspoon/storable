/*

*/

import CoreData


@propertyWrapper
public struct ToOneRelationship<Value: ManagedObject> : ManagedPropertyWrapper
  {
    public let managedProperty : ManagedProperty


    public init(_ propertyName: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestKey k: IngestKey? = nil, ingestMode m: ManagedRelationship.IngestMode? = nil)
      {
        managedProperty = ManagedRelationship(propertyName, arity: .toOne, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, ingestKey: k, ingestMode: m)
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            switch instance.value(forKey: wrapper.managedProperty.name) {
              case .some(let object) :
                return try throwingCast(object, as: Value.self)
              case .none :
                throw Exception("no stored value for '\(wrapper.managedProperty.name)'")
            }
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.managedProperty.name)': \(error)")
          }
        }
        set {
          let wrapper = instance[keyPath: storageKeyPath]
          instance.setValue(newValue, forKey: wrapper.managedProperty.name)
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Use init(_:inverseName:deleteRule:ingestKey:ingestMode:)")
    public init() { fatalError() }

    @available(*, unavailable, message: "Use (_:inverseName:deleteRule:ingestKey:ingestMode:)")
    public init(wrappedValue: Value) { fatalError() }

    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
