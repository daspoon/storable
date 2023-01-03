/*

*/


/// ManagedPropertyWrapper is used to identify property wrappers which implement CoreData-managed properties on subclasses of ManagedObject.
///
public protocol ManagedPropertyWrapper
  {
    var managedProperty : ManagedProperty { get }
  }
