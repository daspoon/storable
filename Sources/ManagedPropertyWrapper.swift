/*

*/


/// ManagedPropertyWrapper is used to identify property wrappers which implement CoreData-managed properties on subclasses of Object.
///
public protocol ManagedPropertyWrapper
  {
    var property : Property { get }
  }
