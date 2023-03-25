/*

  Created by David Spooner

  Extensions to DataStore for the convenience of writing test cases.

*/

import CoreData
import Storable


extension DataStore
  {
    /// Create, insert and initialize an object instance.
    func create<T: ManagedObject>(_ type: T.Type = T.self, initialize f: (T) throws -> Void = {_ in }) throws -> T
      { try managedObjectContext.create(type, initialize: f) }

    /// Fetch an array of objects matching the given predicate and sorted by the given descriptors.
    func fetchObjects<T: ManagedObject>(of type: T.Type = T.self, satisfying predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [T]
      { try managedObjectContext.fetchObjects(makeFetchRequest(for: type, predicate: predicate, sortDescriptors: sortDescriptors)) }

    /// Fetch the unique object satisfying the given predicate.
    func fetchObject<T: ManagedObject>(of type: T.Type = T.self, satisfying predicate: NSPredicate) throws -> T
      { try managedObjectContext.fetchObject(makeFetchRequest(for: type, predicate: predicate)) }
  }
