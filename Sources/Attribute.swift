/*

*/

import CoreData


@propertyWrapper
public struct Attribute<Value: Storable> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo

    private static func ingest(_ json: Any) throws -> Value where Value : Ingestible
      { try Value(json: try throwingCast(json)) }


    public init(_ name: String)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, allowsNilValue: Value.StoredType.isOptional)
      }

    public init(_ name: String)  where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, allowsNilValue: Value.StoredType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(_ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, allowsNilValue: Value.StoredType.isOptional, ingest: (k, Self.ingest))
      }


    public init(wrappedValue v: Value, _ name: String)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, defaultValue: v, allowsNilValue: Value.StoredType.isOptional)
      }

    public init(wrappedValue v: Value, _ name: String) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, defaultValue: v, allowsNilValue: Value.StoredType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(wrappedValue v: Value, _ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, defaultValue: v, allowsNilValue: Value.StoredType.isOptional, ingest: (k, Self.ingest))
      }


    public init<Transform>(_ name: String, ingestKey k: IngestKey? = nil, transform t: Transform, defaultIngestValue v: Transform.Input? = nil) where Value : Ingestible, Transform : IngestTransform, Transform.Output == Value.Input
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
        propertyInfo = AttributeInfo(name: name, type: Value.StoredType.attributeType, defaultValue: tv, allowsNilValue: Value.StoredType.isOptional, ingest: (k ?? .element(name), ingest))
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            // The value maintained by CoreData is of type Value.StoredType; nil is acceptable if Value.isOptional, but otherwise means the property is uninitialized.
            let storedValue : Value.StoredType
            switch instance.value(forKey: wrapper.propertyInfo.name) {
              case .some(let objectValue) :
                storedValue = try throwingCast(objectValue, as: Value.StoredType.self)
              case .none :
                guard Value.StoredType.isOptional else { throw Exception("value is not initialized") }
                storedValue = .nullValue
            }
            return try Value.decodeStoredValue(storedValue)
          }
          catch let error as NSError {
            fatalError("Failed to get value for \(Object.self).\(wrapper.propertyInfo.name): \(error)")
          }
        }
        set {
          let wrapper = instance[keyPath: storageKeyPath]
          do {
            let storedValue = try newValue.storedValue()
            instance.setValue(storedValue, forKey: wrapper.propertyInfo.name)
          }
          catch let error as NSError {
            fatalError("failed to set value of type \(Value.self) for property '\(wrapper.propertyInfo.name)': \(error)")
          }
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
