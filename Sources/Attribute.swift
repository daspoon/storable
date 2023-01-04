/*

*/

import CoreData


@propertyWrapper
public struct Attribute<Value: Ingestible & Storable> : ManagedPropertyWrapper
  {
    public let managedProperty : ManagedProperty

    private static func ingest(_ json: Any) throws -> Value
      { try Value(json: try throwingCast(json)) }


    public init(_ name: String, ingestKey k: IngestKey? = nil)
      {
        managedProperty = ManagedAttribute(name: name, type: Value.attributeType, ingestMethod: Self.ingest, ingestKey: k, allowsNilValue: Value.isOptional)
      }


    public init(wrappedValue v: Value, _ name: String, ingestKey k: IngestKey? = nil)
      {
        managedProperty = ManagedAttribute(name: name, type: Value.attributeType, ingestMethod: Self.ingest, ingestKey: k, allowsNilValue: Value.isOptional, defaultValue: v)
      }


    public init<Transform>(_ name: String, ingestKey key: IngestKey? = nil, transform t: Transform, defaultIngestValue v: Transform.Input? = nil) where Transform : IngestTransform, Transform.Output == Value.Input
      {
        func ingest(_ json: Any) throws -> Value {
          try Value(json: try t.transform(try throwingCast(json)))
        }
        let tv = v.map {
          do { return try ingest($0) }
          catch let error as NSError {
            fatalError("failed to transform default value '\($0)' of attribute \(name): \(error)")
          }
        }
        managedProperty = ManagedAttribute(name: name, type: Value.attributeType, ingestMethod: ingest, ingestKey: key, allowsNilValue: Value.isOptional, defaultValue: tv)
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          // Retrieve and decode the stored object value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            switch (instance.value(forKey: wrapper.managedProperty.name), Value.isOptional) {
              case (.some(let objectValue), _) :
                let storedValue = try throwingCast(objectValue, as: Value.StoredType.self)
                return try Value.decodeStoredValue(storedValue)
              case (.none, true) :
                return Value.nullValue
              case (.none, false) :
                throw Exception("no stored value for '\(wrapper.managedProperty.name)'")
            }
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.managedProperty.name)': \(error)")
          }
        }
        set {
          // Encode and store the new value
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            let storedValue = newValue.isNullValue ? nil : try newValue.storedValue()
            instance.setValue(storedValue, forKey: wrapper.managedProperty.name)
          }
          catch let error as NSError {
            fatalError("failed to set value of type \(Value.self) for property '\(wrapper.managedProperty.name)': \(error)")
          }
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
