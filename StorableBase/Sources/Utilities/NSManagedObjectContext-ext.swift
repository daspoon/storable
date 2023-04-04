/*

  Created by David Spooner

*/

import CoreData


/// Convenience methods added to NSManagedObjectContext.

extension NSManagedObjectContext
  {
    /// Create, initialize and insert an instance of the given managed object type.
    @discardableResult
    public func create<T: ManagedObject>(_ type: T.Type = T.self, initialize: (T) throws -> Void = {_ in }) throws -> T
      {
        guard let entity = persistentStoreCoordinator?.managedObjectModel.entitiesByName[type.entityName] else { throw Exception("unknown entity \(type.entityName)") }
        let instance = type.init(entity: entity, insertInto: self)
        try initialize(instance)
        return instance
      }


    /// Return the result of executing the given fetch request.
    public func fetchObjects<T: ManagedObject>(_ request: NSFetchRequest<T>) throws -> [T]
      {
        request.resultType = .managedObjectResultType
        return try fetch(request)
      }


    /// Return the single object satisfying the given fetch request, or nil if none exist. Throw if multiple matching objects exist.
    public func tryFetchObject<T: ManagedObject>(_ request: NSFetchRequest<T>) throws -> T?
      {
        let results = try fetchObjects(request)
        switch results.count {
          case 1 :
            return results[0]
          case 0 :
            return nil
          default :
            throw Exception("multiple \(request.entityName!) instances" + (request.predicate.map {" satisfying '\($0)'"} ?? ""))
        }
      }


    /// Return the single match for the given fetch request, throwing if there is not exactly one.
    public func fetchObject<T: ManagedObject>(_ request: NSFetchRequest<T>) throws -> T
      {
        guard case .some(let object) = try tryFetchObject(request)
          else { throw Exception("no \(String(describing: request.entityName)) instance satisfying '\(String(describing: request.predicate))'") }

        return object
      }
  }
