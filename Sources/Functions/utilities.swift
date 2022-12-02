/*

*/

import Foundation
import CoreData


public func log(_ message: @autoclosure () -> String, function: String = #function)
  { print("--- \(function) - \(message())") }


public func sign<T: BinaryInteger>(_ i: T) -> T
  { i < 0 ? -1 : 1 }


public func fetchRequest<T: NSManagedObject>(for type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<T>
  {
    let fetchRequest = NSFetchRequest<T>(entityName: NSStringFromClass(T.self))
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = sortDescriptors
    return fetchRequest
  }

