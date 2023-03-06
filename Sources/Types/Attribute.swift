/*

  Created by David Spooner

*/

import CoreData


/// Attribute is a property wrapper used to declared managed non-optional attributes on subclasses of Entity.

@propertyWrapper
public struct Attribute<Value: Storable> : ManagedPropertyWrapper
  {
    public let propertyInfo : PropertyInfo


    /// Declare an attribute which has no default value.
    public init(_ name: String, renamingIdentifier: String? = nil)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier)
      }

    /// Declare an attribute which has no default value and is ingestible.
    public init(_ name: String, renamingIdentifier: String? = nil) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier, ingest: (.element(name), Value.ingest))
      }

    /// Declare an attribute which has no default value and is ingestible using the specified key.
    public init(_ name: String, renamingIdentifier: String? = nil, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, renamingIdentifier: renamingIdentifier, ingest: (k, Value.ingest))
      }

    /// Declare an attribute which has a default value.
    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier)
      }

    /// Declare an attribute which has a default value and is ingestible.
    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier, ingest: (.element(name), Value.ingest))
      }

    /// Declare an attribute which has a default value and is ingestible using the specified key.
    public init(wrappedValue v: Value, _ name: String, renamingIdentifier: String? = nil, ingestKey k: IngestKey) where Value : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: v, renamingIdentifier: renamingIdentifier, ingest: (k, Value.ingest))
      }

    /// Declare an attribute which is transformed from an alternate format on ingestion. If a default value is provided, it must be of the input type of the given transform.
    public init<Transform>(_ name: String, renamingIdentifier: String? = nil, ingestKey k: IngestKey? = nil, transform t: Transform, defaultIngestValue v: Transform.Input? = nil) where Value : Ingestible, Transform : IngestTransform, Transform.Output == Value.Input
      {
        // Transform the given default value.
        let tv = v.map {try! Value.ingest($0, withTransform: t)}
        propertyInfo = AttributeInfo(name: name, type: Value.self, defaultValue: tv, renamingIdentifier: renamingIdentifier, ingest: (k ?? .element(name), {try Value.ingest($0, withTransform: t)}))
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
