/*

*/

import CoreData


/// Fetched is a property wrapper for declaring fetched properties on subclasses of Object. It provides an initializer for each of the four cases of NSFetchedResultType.

@propertyWrapper
public struct Fetched<Value> : ManagedProperty
  {
    public let propertyInfo : PropertyInfo


    /// Create an instance corresponding to an array of managed objects
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [T]
      {
        fetchRequest.resultType = .managedObjectResultType
        propertyInfo = FetchedInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to an array of managed object identifiers
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [NSManagedObjectID]
      {
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.includesPropertyValues = false
        propertyInfo = FetchedInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to a dictionary of property name/value pairs. Set the fetchRequest's propertiesToFetch to determine the entries of the resulting dictionaries.
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == [[String: Any]]
      {
        fetchRequest.resultType = .dictionaryResultType
        propertyInfo = FetchedInfo(name: name, fetchRequest: fetchRequest)
      }

    /// Create an instance corresponding to an an integer count of matching objects.
    public init<T: NSManagedObject>(_ name: String, fetchRequest: NSFetchRequest<T>) where Value == Int
      {
        fetchRequest.resultType = .countResultType
        propertyInfo = FetchedInfo(name: name, fetchRequest: fetchRequest)
      }


    /// The enclosing-self subscript which implements readonly access to the associated property value.
    public static subscript<Object: NSManagedObject>(_enclosingInstance instance: Object, wrapped wrappedKeyPath: ReferenceWritableKeyPath<Object, Value>, storage storageKeyPath: ReferenceWritableKeyPath<Object, Self>) -> Value
      {
        get {
          let info = instance[keyPath: storageKeyPath].propertyInfo
          guard let value = instance.value(forKey: info.name) else {
            fatalError("nil value for fetched property")
          }
          return value as! Value
        }
      }


    /// The wrappedValue cannot be implemented without access to the enclosing object, and so is marked unavailable.
    @available(*, unavailable, message: "Unsupported")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }
  }


// A convenience method for creating instances of NSFetchRequest for use in Fetched-wrapped properties.

public func makeFetchRequest<T: NSManagedObject>(for type: T.Type = T.self,
    predicate: NSPredicate? = nil,
    sortDescriptors: [NSSortDescriptor] = [],
    propertiesToFetch: [String]? = nil,
    includesPendingChanges: Bool = true,
    includesPropertyValues: Bool = true,
    includesSubentities: Bool = true
  ) -> NSFetchRequest<T>
  {
    let request = NSFetchRequest<T>()
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    request.propertiesToFetch = propertiesToFetch
    request.includesPendingChanges = includesPendingChanges
    request.includesPropertyValues = includesPropertyValues
    request.includesSubentities = includesSubentities
    return request
  }

