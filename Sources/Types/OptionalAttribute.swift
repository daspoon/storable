/*

  Created by David Spooner

*/

import CoreData


/// OptionalAttribute is a property wrapper used to declare optional managed attributes on subclasses of Entity.

@propertyWrapper
public struct OptionalAttribute<Value: Nullable> : ManagedProperty where Value.Wrapped : Storable
  {
    public let propertyInfo : PropertyInfo


    /// Declare an optional attribute.
    public init(_ name: String, renamingIdentifier: String? = nil)
      {
        propertyInfo = AttributeInfo(name: name, type: Value.Wrapped.self, isOptional: true, renamingIdentifier: renamingIdentifier)
      }

    /// Declare an optional attribute which is ingestible.
    public init(_ name: String, renamingIdentifier: String? = nil) where Value.Wrapped : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.Wrapped.self, isOptional: true, renamingIdentifier: renamingIdentifier, ingest: (.element(name), Value.Wrapped.ingest))
      }

    /// Declare an optional attribute which is ingestible using the specified key.
    public init(_ name: String, renamingIdentifier: String? = nil, ingestKey k: IngestKey) where Value.Wrapped : Ingestible
      {
        propertyInfo = AttributeInfo(name: name, type: Value.Wrapped.self, isOptional: true, renamingIdentifier: renamingIdentifier, ingest: (k, Value.Wrapped.ingest))
      }

    /// Declare an optional attribute which is transformed from an alternate format on ingestion.
    public init<Transform>(_ name: String, renamingIdentifier: String? = nil, ingestKey k: IngestKey? = nil, transform t: Transform) where Value.Wrapped : Ingestible, Transform : IngestTransform, Transform.Output == Value.Wrapped.Input
      {
        propertyInfo = AttributeInfo(name: name, type: Value.Wrapped.self, isOptional: true, renamingIdentifier: renamingIdentifier, ingest: (k ?? .element(name), {try Value.Wrapped.ingest($0, withTransform: t)}))
      }


    /// The enclosing-self subscript which implements access and update of the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          // Note that the value maintained by CoreData is of type Value.StoredType?, but nil indicates the property is uninitialized.
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          switch instance.value(forKey: propertyInfo.name) {
            case .some(let anyValue) :
              guard let encodedValue = anyValue as? Value.Wrapped.EncodingType else { fatalError("\(Object.self).\(propertyInfo.name) is not of expected type \(Value.Wrapped.EncodingType.self)") }
              return Value.inject(Value.Wrapped.decodeStoredValue(encodedValue))
            case .none :
              return nil
          }
        }
        set {
          let propertyInfo = instance[keyPath: storageKeyPath].propertyInfo
          instance.setValue(Value.project(newValue)?.storedValue(), forKey: propertyInfo.name)
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
