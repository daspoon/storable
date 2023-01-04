/*

*/

import CoreData


@propertyWrapper
public struct ToOptionalRelationship<Value: Nullable> : ManagedPropertyWrapper where Value.Wrapped : ManagedObject
  {
    public let managedProperty : ManagedProperty


    public init(_ propertyName: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestKey k: IngestKey? = nil, ingestMode m: ManagedRelationship.IngestMode? = nil)
      {
        managedProperty = ManagedRelationship(propertyName, arity: .optionalToOne, relatedEntityName: Value.Wrapped.entityName, inverseName: inverseName, deleteRule: r, ingestKey: k, ingestMode: m)
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            let value : Value
            switch instance.value(forKey: wrapper.managedProperty.name) {
              case .some(let object) :
                value = Value.inject(try throwingCast(object, as: Value.Wrapped.self))
              case .none :
                value = nil
            }
            return value
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.managedProperty.name)': \(error)")
          }
        }
        set {
          let wrapper = instance[keyPath: storageKeyPath]
          instance.setValue(newValue.project, forKey: wrapper.managedProperty.name)
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
