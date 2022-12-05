/*

*/

import CoreData


@propertyWrapper
public struct Persistent<Value: Codable>
  {
    public init()
      { }

    public init(wrappedValue: Value)
      { }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let key = NSExpression(forKeyPath: wrappedKeyPath).keyPath
          guard let data = instance.primitiveValue(forKey: key) as? Data else { fatalError("failed to retrieve data for '\(key)") }
          do {
            return try JSONDecoder().decode(Value.self, from: data)
          }
          catch let error {
            fatalError("failed to decode value of type \(Value.self) for '\(key)" + error.localizedDescription)
          }
        }
        set {
          let key = NSExpression(forKeyPath: wrappedKeyPath).keyPath
          do {
            instance.setPrimitiveValue(try JSONEncoder().encode(newValue), forKey: key)
          }
          catch let error {
            fatalError("failed to encode value of type \(Value.self) for '\(key)" + error.localizedDescription)
          }
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Accessible only as a property on an NSManagedObject")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
