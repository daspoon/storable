/*

*/

import CoreData


/// FetchedProperty is a property wrapper for declaring fetched properties on subclasses of Entity. It provides an initializer for each of the four cases of NSFetchedResultType.
/// Note that the predicate of a FetchedProperty can access the enclosing object via $FETCH_SOURCE.

@propertyWrapper
public struct FetchedProperty<Value> : ManagedProperty
  {
    let fetchedPropertyInfo : FetchedPropertyInfo

    public var propertyInfo : PropertyInfo
      { fetchedPropertyInfo }


    /// Create an instance corresponding to an array of managed objects
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [T]
      {
        fetchRequest.resultType = .managedObjectResultType
        fetchedPropertyInfo = FetchedPropertyInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to an array of managed object identifiers
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [NSManagedObjectID]
      {
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.includesPropertyValues = false
        fetchedPropertyInfo = FetchedPropertyInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to a dictionary of property name/value pairs. Set the fetchRequest's propertiesToFetch to determine the entries of the resulting dictionaries.
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [[String: Any]]
      {
        fetchRequest.resultType = .dictionaryResultType
        fetchedPropertyInfo = FetchedPropertyInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to an an integer count of matching objects. Note that entity type of the fetch request must be explicit, as it canot be determined by the property type Int.
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == Int
      {
        fetchRequest.resultType = .countResultType
        fetchRequest.includesPropertyValues = false
        fetchedPropertyInfo = FetchedPropertyInfo(name: name, fetchRequest: fetchRequest)
      }


    /// The enclosing-self subscript which implements readonly access to the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let info = instance[keyPath: storageKeyPath].fetchedPropertyInfo
          let result = instance.value(forKey: info.name)
          switch info.fetchRequest.resultType {
            case .countResultType :
              // In this case the result is an array of int.
              guard let array = result as? [Value], array.count == 1 else {
                fatalError("expecting [Int] as fetched result type: \(String(describing: result))")
              }
              return array[0]
            default :
              guard let value = result as? Value else {
                fatalError("expecting \(Value.self) as fetched result type: \(String(describing: result))")
              }
              return value
          }
        }
        set { }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }
