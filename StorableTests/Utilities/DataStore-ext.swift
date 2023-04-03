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
      { try managedObjectContext.fetchObjects(fetchRequest(for: type, predicate: predicate, sortDescriptors: sortDescriptors)) }

    /// Fetch the unique object satisfying the given predicate.
    func fetchObject<T: ManagedObject>(of type: T.Type = T.self, satisfying predicate: NSPredicate) throws -> T
      { try managedObjectContext.fetchObject(fetchRequest(for: type, predicate: predicate)) }

    /// Migrate the store from a model consisting only of the given source entity to a model consisting only of the given target entity.
    func migrate(from sourceEntity: NSEntityDescription, to targetEntity: NSEntityDescription) throws
      {
        let sourceModel = NSManagedObjectModel(entities: [sourceEntity.copy() as! NSEntityDescription])
        let targetModel = NSManagedObjectModel(entities: [targetEntity.copy() as! NSEntityDescription])
        try self.migrate(from: sourceModel, to: targetModel)
      }

    /// Update the store, which is expected to be consistent with the model consisting only of the given entity, using the given procedure.
    func update(as entity: NSEntityDescription, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        let model = NSManagedObjectModel(entities: [entity.copy() as! NSEntityDescription])
        try self.update(as: model, using: script)
      }
  }
