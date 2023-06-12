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


    /// Fetch the single object of the given type and name.
    public func fetchObject<T: ManagedObject>(id name: String, of type: T.Type = T.self) throws -> T
      { try fetchObject(fetchRequest(for: type, predicate: .init(format: "name = %@", name))) }
  }


// MARK: -

fileprivate var editingContextKey : Int = 0

extension NSManagedObjectContext
  {
    /// Return the associated editing context, if any.
    public var editingContext : EditingContext?
      {
        get { objc_getAssociatedObject(self, &editingContextKey) as? EditingContext }
        set { objc_setAssociatedObject(self, &editingContextKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN) }
      }


    /// Save the given context and each of its ancestors, invoking the given completion block, if any, on the main queue.
    public func performSave(completion: ((Error?) -> Void)? = nil)
      {
        do {
          log("saving \(name ?? "<unnamed>") context")

          // If we have a parent context then make note of the inserted objects.
          let inserted = parent != nil ? Array(insertedObjects) : []

          // Merge our changes into the parent context (or into the persistent store if parent is nil).
          try save()

          // If we have a parent context then recursively save it, then obtain permanent ids for the inserted objects and finally invoke the completion handler; otherwise just invoke the completion handler.
          if let parent {
            parent.perform {
              parent.performSave { error in
                if error == nil {
                  do { try self.obtainPermanentIDs(for: inserted) }
                  catch {
                    log("context \(self.name ?? "<unnamed>") failed to resolve inserted objects")
                  }
                }
                completion?(error)
              }
            }
          }
          else {
            performSaveDidComplete(with: nil, callback: completion)
          }
        }
        catch {
          performSaveDidComplete(with: error, callback: completion)
        }
      }


    /// Called upon completing a requested save operation. Log and broadcast the the generated error, if any, and invoke the requested completion callback.
    private func performSaveDidComplete(with error: Error?, callback: ((Error?) -> Void)?)
      {
        if let error {
          log("\(error)")
          NotificationCenter.default.post(name: .dataStoreSaveDidFail, object: self, userInfo: [
            "error": error as NSError,
          ])
        }

        callback.map { f in DispatchQueue.main.async { f(error) } }
      }


    /// Return the error which would be thrown if on saving.
    public var validationError : NSError?
      {
        var errors : [NSError] = []
        // Accumulate validation errors for inserted objects
        for object in insertedObjects {
          do { try object.validateForInsert() }
          catch {
            errors.append(error as NSError)
          }
        }
        // Accumulate validation errors for inserted objects
        for object in updatedObjects {
          do { try object.validateForUpdate() }
          catch {
            errors.append(error as NSError)
          }
        }
        // Accumulate validation errors for inserted objects
        for object in deletedObjects {
          do { try object.validateForDelete() }
          catch {
            errors.append(error as NSError)
          }
        }
        // Return an appropriate error, mimicing CoreData's aggregate error if necessary.
        switch errors.count {
          case 0 : return nil
          case 1 : return errors[0]
          default :
            return NSError(domain: "NSCocoaErrorDomain", code: 1560, userInfo: [
              NSLocalizedDescriptionKey : "Multiple validation errors occurred.",
              NSDetailedErrorsKey : errors,
            ])
        }
      }
  }
