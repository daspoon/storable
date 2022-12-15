/*

*/

import CoreData


@propertyWrapper
public struct Stored<Value: Storable>
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
          // Retrieve and decode the stored object value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            switch (instance.primitiveValue(forKey: wrapper.key), Value.isOptional) {
              case (.some(let objectValue), _) :
                let storedValue = try throwingCast(objectValue, as: Value.StoredType.self)
                return try Value.decodeStoredValue(storedValue)
              case (.none, true) :
                return Value.nullValue
              case (.none, false) :
                throw Exception("no stored value for '\(wrapper.key)'")
            }
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.key)': \(error)")
          }
        }
        set {
          // Encode and store the new value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            let storedValue = newValue.isNullValue ? nil : try newValue.storedValue()
            instance.setPrimitiveValue(storedValue, forKey: wrapper.key)
          }
          catch let error as NSError {
            fatalError("failed to set value of type \(Value.self) for property '\(wrapper.key)': \(error)")
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
