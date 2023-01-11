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
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, allowsNilValue: Value.EncodingType.isOptional)
      }

    public init(_ name: String)  where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, allowsNilValue: Value.EncodingType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(_ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, allowsNilValue: Value.EncodingType.isOptional, ingest: (k, Self.ingest))
      }


    public init(wrappedValue v: Value, _ name: String)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional)
      }

    public init(wrappedValue v: Value, _ name: String) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(wrappedValue v: Value, _ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional, ingest: (k, Self.ingest))
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
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, defaultValue: tv, allowsNilValue: Value.EncodingType.isOptional, ingest: (k ?? .element(name), ingest))
      }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          instance[keyPath: storageKeyPath].getWrappedValue(from: instance)
        }
        set {
          instance[keyPath: storageKeyPath].setWrappedValue(newValue, on: instance)
        }
      }


    private func getWrappedValue<Object: NSManagedObject>(from instance: Object) -> Value
      {
        // Note that the value maintained by CoreData is of type Value.StoredType?, but nil is an acceptable value only if Value.isOptional; otherwise the property is uninitialized.
        do {
          let storedValue : Value.EncodingType
          switch instance.value(forKey: propertyInfo.name) {
            case .some(let objectValue) :
              storedValue = try throwingCast(objectValue, as: Value.EncodingType.self)
            case .none :
              guard Value.EncodingType.isOptional else { throw Exception("value is not initialized") }
              storedValue = .nullValue
          }
          return try Value.decodeStoredValue(storedValue)
        }
        catch let error as NSError {
          fatalError("Failed to get value for \(Object.self).\(propertyInfo.name): \(error)")
        }
      }


    private func setWrappedValue<Object: NSManagedObject>(_ value: Value, on instance: Object)
      {
        // Note that if storeValue.isNullValue then storedValue is nil, but would be translated by Swift to NSNull and so we must explicitly substitute nil.
        do {
          let storedValue = try value.storedValue()
          instance.setValue(storedValue.isNullValue ? nil : storedValue, forKey: propertyInfo.name)
        }
        catch let error as NSError {
          fatalError("failed to set value of type \(Value.self) for property '\(propertyInfo.name)': \(error)")
        }
      }


    // Unavailable

    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
