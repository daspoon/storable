/*

*/

import CoreData


/// Attribute is a property wrapper used to declared managed attributes on subclasses of Object.

@propertyWrapper
public struct Attribute<Value: Storable> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo

    private static func ingest(_ json: Any) throws -> Value where Value : Ingestible
      { try Value(json: try throwingCast(json)) }


    // Initializers without explicit initial values.

    public init(_ name: String)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, allowsNilValue: Value.EncodingType.isOptional)
      }

    public init(_ name: String)  where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, allowsNilValue: Value.EncodingType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(_ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, allowsNilValue: Value.EncodingType.isOptional, ingest: (k, Self.ingest))
      }


    // Initializers with explicit initial values

    public init(wrappedValue v: Value, _ name: String)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional)
      }

    public init(wrappedValue v: Value, _ name: String) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional, ingest: (.element(name), Self.ingest))
      }

    public init(wrappedValue v: Value, _ name: String, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, defaultValue: v, allowsNilValue: Value.EncodingType.isOptional, ingest: (k, Self.ingest))
      }


    // Initializers with values transformed on ingestion

    public init<Transform>(_ name: String, ingestKey k: IngestKey? = nil, transform t: Transform, defaultIngestValue v: Transform.Input? = nil) where Value : Ingestible, Transform : IngestTransform, Transform.Output == Value.Input
      {
        // The ingestion method must first apply the given transform to its argument.
        func ingest(_ json: Any) throws -> Value {
          try Value(json: try t.transform(try throwingCast(json)))
        }
        // Transform the given default value.
        let tv = v.map {
          do { return try ingest($0) }
          catch let error as NSError {
            fatalError("failed to transform default value '\($0)' of attribute \(name): \(error)")
          }
        }
        propertyInfo = AttributeInfo(name: name, type: Value.EncodingType.typeId, transformerName: Value.valueTransformerName, defaultValue: tv, allowsNilValue: Value.EncodingType.isOptional, ingest: (k ?? .element(name), ingest))
      }


    /// The enclosing-self subscript which implements access and update of the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          // Note that the value maintained by CoreData is of type Value.StoredType?, but nil is an acceptable value only if Value.isOptional; otherwise the property is uninitialized.
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          let storedValue : Value.EncodingType
          switch instance.value(forKey: propertyInfo.name) {
            case .some(let objectValue) :
              guard let encodedValue = objectValue as? Value.EncodingType else { fatalError("\(Object.self).\(propertyInfo.name) is not of expected type \(Value.EncodingType.self)") }
              storedValue = encodedValue
            case .none :
              guard Value.EncodingType.isOptional else { fatalError("\(Object.self).\(propertyInfo.name) is not initialized") }
              storedValue = .nullValue
          }
          return Value.decodeStoredValue(storedValue)
        }
        set {
          // Note that if storeValue.isNullValue then storedValue is nil, but would be translated by Swift to NSNull and so we must explicitly substitute nil.
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          let storedValue = newValue.storedValue()
          instance.setValue(storedValue.isNullValue ? nil : storedValue, forKey: propertyInfo.name)
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
