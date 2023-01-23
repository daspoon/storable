/*

*/

import CoreData


/// Print a message to the console which includes the name of the enclosing function.
public func log(_ message: @autoclosure () -> String, function: String = #function)
  { print("--- \(function) - \(message())") }


/// Return the given value cast to the specified type, throwing an Exception on failure.
public func throwingCast<T>(_ v: Any, as: T.Type = T.self) throws -> T
  {
    guard let t = v as? T else { throw Exception("expecting value of type \(T.self)") }
    return t
  }


/// Convenience method for creating NSFetchRequests.
public func makeFetchRequest<T: Object>(
    for type: T.Type = T.self,
    predicate: NSPredicate? = nil,
    sortDescriptors: [NSSortDescriptor] = [],
    propertiesToFetch: [String]? = nil,
    includesPendingChanges: Bool = true,
    includesPropertyValues: Bool = true,
    includesSubentities: Bool = true
  ) -> NSFetchRequest<T>
  {
    let request = NSFetchRequest<T>(entityName: type.entityName)
    request.predicate = predicate
    request.sortDescriptors = sortDescriptors
    request.propertiesToFetch = propertiesToFetch
    request.includesPendingChanges = includesPendingChanges
    request.includesPropertyValues = includesPropertyValues
    request.includesSubentities = includesSubentities
    return request
  }

