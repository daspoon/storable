/*

*/

import CoreData


/// Attribute is a property wrapper used to declared managed attributes on subclasses of Object.

@propertyWrapper
public struct Attribute<Value: Storable> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo


    // Initializers without explicit initial values.

    public init(_ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier)
      }

    public init(_ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil)  where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier, ingest: (.element(name), Value.ingest))
      }

    public init(_ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier, ingest: (k, Value.ingest))
      }


    // Initializers with explicit initial values

    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier)
      }

    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier, ingest: (.element(name), Value.ingest))
      }

    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier, ingest: (k, Value.ingest))
      }


    // Initializers with values transformed on ingestion

    public init<Transform>(_ name: String, renamingIdentifier: String? = nil, versionHashModifier: String? = nil, ingestKey k: IngestKey? = nil, transform t: Transform, defaultIngestValue v: Transform.Input? = nil) where Value : Ingestible, Transform : IngestTransform, Transform.Output == Value.Input
      {
        // Transform the given default value.
        let tv = v.map {try! Value.ingest($0, withTransform: t)}
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: tv, renamingIdentifier: renamingIdentifier, versionHashModifier: versionHashModifier, ingest: (k ?? .element(name), {try Value.ingest($0, withTransform: t)}))
      }


    /// The enclosing-self subscript which implements access and update of the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          // The value maintained by CoreData is either nil or of type Value.StoredType; a nil value indicates the property is uninitialized.
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          switch instance.value(forKey: propertyInfo.name) {
            case .some(let objectValue) :
              guard let encodedValue = objectValue as? Value.EncodingType else { fatalError("\(Object.self).\(propertyInfo.name) is not of expected type \(Value.EncodingType.self)") }
              return Value.decodeStoredValue(encodedValue)
            case .none :
              fatalError("\(Object.self).\(propertyInfo.name) is not initialized")
          }
        }
        set {
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          instance.setValue(newValue.storedValue(), forKey: propertyInfo.name)
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
