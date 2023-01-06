/*

*/


/// ManagedPropertyWrapper is used to identify property wrappers which implement CoreData-managed properties on subclasses of ManagedObject.
///
public protocol ManagedProperty
  {
    var propertyInfo : PropertyInfo { get }
  }
