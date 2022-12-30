/*

*/

import CoreData


@propertyWrapper
public struct Stored<Value: Ingestible & Storable> : ManagedPropertyWrapper
  {
    public let property : Property


    public init(_ name: String, ingestKey key: IngestKey? = nil, defaultValue v: Value? = nil)
      {
        func ingest(_ json: Any) throws -> Value {
          try Value(json: try throwingCast(json))
        }
        property = Attribute(name: name, type: Value.attributeType, ingestMethod: ingest, ingestKey: key, allowsNilValue: Value.isOptional, defaultValue: v)
      }


    public init<Transform>(_ name: String, ingestKey key: IngestKey? = nil, transform t: Transform, defaultValue v: Transform.Input? = nil) where Transform : IngestTransform, Transform.Output == Value.Input
      {
        func ingest(_ json: Any) throws -> Value {
          try Value(json: try t.transform(try throwingCast(json)))
        }
        property = Attribute(name: name, type: Value.attributeType, ingestMethod: ingest, ingestKey: key, allowsNilValue: Value.isOptional, defaultValue: v)
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          // Retrieve and decode the stored object value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            switch (instance.primitiveValue(forKey: wrapper.property.name), Value.isOptional) {
              case (.some(let objectValue), _) :
                let storedValue = try throwingCast(objectValue, as: Value.StoredType.self)
                return try Value.decodeStoredValue(storedValue)
              case (.none, true) :
                return Value.nullValue
              case (.none, false) :
                throw Exception("no stored value for '\(wrapper.property.name)'")
            }
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.property.name)': \(error)")
          }
        }
        set {
          // Encode and store the new value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            let storedValue = newValue.isNullValue ? nil : try newValue.storedValue()
            instance.setPrimitiveValue(storedValue, forKey: wrapper.property.name)
          }
          catch let error as NSError {
            fatalError("failed to set value of type \(Value.self) for property '\(wrapper.property.name)': \(error)")
          }
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Use init(_:ingestKey:defaultValue:) or init(_:ingestKey:transform:defaultValue:)")
    public init() { fatalError() }

    @available(*, unavailable, message: "Use init(_:ingestKey:defaultValue:) or init(_:ingestKey:transform:defaultValue:)")
    public init(wrappedValue: Value) { fatalError() }

    @available(*, unavailable, message: "Accessible only as a property on an NSManagedObject")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
