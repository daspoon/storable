/*

*/

import CoreData


@propertyWrapper
public struct Persistent<Value: Codable>
  {
    let key : String


    public init(_ key: String)
      { self.key = key }

    public init(wrappedValue _: Value, _ key: String)
      { self.key = key }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let key : String = instance[keyPath: storageKeyPath].key
          guard let data = instance.primitiveValue(forKey: key) as? Data else { fatalError("failed to retrieve data for '\(key)") }
          do {
            return try JSONDecoder().decode(Value.self, from: data)
          }
          catch let error {
            fatalError("failed to decode value of type \(Value.self) for '\(key)" + error.localizedDescription)
          }
        }
        set {
          let key : String = instance[keyPath: storageKeyPath].key
          do {
            instance.setPrimitiveValue(try JSONEncoder().encode(newValue), forKey: key)
          }
          catch let error {
            fatalError("failed to encode value of type \(Value.self) for '\(key)" + error.localizedDescription)
          }
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Use init(_:) instead.")
    public init() { fatalError() }

    @available(*, unavailable, message: "Use init(wrappedValue:_:) instead.")
    public init(wrappedValue: Value) { fatalError() }

    @available(*, unavailable, message: "Accessible only as a property on an NSManagedObject")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
