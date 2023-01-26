/*

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore
  {
    let schema : Schema
    let managedObjectModel : NSManagedObjectModel
    public let managedObjectContext : NSManagedObjectContext


    public init(schema s: Schema, reset: Bool = false) throws
      {
        schema = s

        // Retain the schema's object model.
        managedObjectModel = s.managedObjectModel

        // Create the managed object context
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        // Associate the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: schema.managedObjectModel)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        // Determine the location of the data store
        let applicationDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let dataStoreURL = URL(string: "\(schema.name).sqlite", relativeTo: applicationDocumentsURL)!

        // Optionally delete the data store (for debugging)
        if reset && FileManager.default.fileExists(atPath: dataStoreURL.path) {
          try FileManager.default.removeItem(at: dataStoreURL)
        }

        // Migrate if necessary
        if FileManager.default.fileExists(atPath: dataStoreURL.path) {
          // Get the metadata for the persistent store
          let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: dataStoreURL)

          // Get the model for the given metadata along with the list of steps required to migrate the store to the current object model.
          let path = try schema.migrationPath(forStoreMetadata: metadata)

          // Iteratively perform the migration steps on the persistent store, passing along the store model
          _ = try path.migrationSteps.reduce(path.sourceModel) { (sourceModel, migrationStep) in
            log("\(migrationStep)")
            return try migrationStep.apply(to: dataStoreURL, of: sourceModel)
          }
        }

        // Open the persistent store
        _ = try persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: dataStoreURL)

        // Observe notifications to trigger saving changes
        NotificationCenter.default.addObserver(self, selector: #selector(performSave(_:)), name: .dataStoreNeedsSave, object: nil)
      }


    public convenience init(schema: Schema, stateEntityName: String = "State", dataSource: DataSource, reset: Bool) throws
      {
        // Ensure the State entity is defined and as has a single instance.
        guard let stateEntity = schema.entitiesByName[stateEntityName] else { throw Exception("Entity '\(stateEntityName)' is not defined") }
        guard case .singleton = stateEntity.managedObjectClass.identity else { throw Exception("Entity '\(stateEntityName)' must have a single instance") }

        // Defer to the designated initializer
        try self.init(schema: schema, reset: reset)

        // Retrieve the configuration if one exists; otherwise trigger ingestion from the data source.
        var configurations = try managedObjectContext.fetch(NSFetchRequest<Object>(entityName: stateEntityName))
        switch configurations.count {
          case 1 :
            break
          case 0 :
            try IngestContext.populate(dataStore: self, from: dataSource)
            configurations = try managedObjectContext.fetch(NSFetchRequest<Object>(entityName: stateEntityName))
            guard configurations.count == 1 else {
              throw Exception("inconsistency after ingestion: \(configurations.count) configurations detected")
            }
          default :
            throw Exception("inconsistency on initialization: \(configurations.count) configurations detected")
        }
      }


    deinit
      {
        NotificationCenter.default.removeObserver(self, name: .dataStoreNeedsSave, object: nil)

        // Note: without the following, running migration unit tests results in a console message stating "BUG IN CLIENT OF libsqlite3.dylib: database integrity compromised by API violation: vnode unlinked while in use"
        if let persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator {
          for store in persistentStoreCoordinator.persistentStores {
            do { try persistentStoreCoordinator.remove(store) }
            catch let error {
              log("failed to remove persistent store \(String(describing: store.url)) -- \(error)")
            }
          }
        }
      }


    public func create<T: Object>(_ type: T.Type = T.self, initialize f: (T) throws -> Void) throws -> T
      { try managedObjectContext.create(type, initialize: f) }

    public func fetchObjects<T: Object>(_ request: NSFetchRequest<T>) throws -> [T]
      { try managedObjectContext.fetchObjects(request) }

    public func fetchObject<T: Object>(_ request: NSFetchRequest<T>) throws -> T
      { try managedObjectContext.fetchObject(request) }

    public func fetchObjects<T: Object>(of type: T.Type = T.self, satisfying predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [T]
      { try managedObjectContext.fetchObjects(makeFetchRequest(for: type, predicate: predicate, sortDescriptors: sortDescriptors)) }

    public func fetchObject<T: Object>(of type: T.Type = T.self, satisfying predicate: NSPredicate) throws -> T
      { try managedObjectContext.fetchObject(makeFetchRequest(for: type, predicate: predicate)) }


    public func save() throws
      { try managedObjectContext.save() }


    @objc
    func performSave(_ sender: Any? = nil)
      {
        do { try save() }
        catch let error as NSError {
          log("failed to save: \(error)")
        }
      }
  }
