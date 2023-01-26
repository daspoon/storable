/*

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore
  {
    let schemaVersions : [Schema]
    let managedObjectModel : NSManagedObjectModel
    public let managedObjectContext : NSManagedObjectContext


    public init(schema s: Schema, priorVersions vs: [Schema] = [], reset: Bool = false) throws
      {
        precondition((vs + [s]).enumerated().allSatisfy {$1.name == s.name && $1.version == $0 + 1})

        schemaVersions = vs + [s]

        // Construct the managed object model and the mapping of entity names to info required for instance creation.
        managedObjectModel = s.managedObjectModel

        // Create the managed object context
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)

        // Associate the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
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
          try migrateIfNecessary(dataStoreURL)
        }

        // Open the persistent store
        _ = try persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: dataStoreURL)

        // Observe notifications to trigger saving changes
        NotificationCenter.default.addObserver(self, selector: #selector(performSave(_:)), name: .dataStoreNeedsSave, object: nil)
      }


    public convenience init(schema: Schema, priorVersions vs: [Schema] = [], stateEntityName: String = "State", dataSource: DataSource, reset: Bool) throws
      {
        // Ensure the State entity is defined and as has a single instance.
        guard let stateEntity = schema.entitiesByName[stateEntityName] else { throw Exception("Entity '\(stateEntityName)' is not defined") }
        guard case .singleton = stateEntity.managedObjectClass.identity else { throw Exception("Entity '\(stateEntityName)' must have a single instance") }

        // Defer to the designated initializer
        try self.init(schema: schema, priorVersions: vs, reset: reset)

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


    private func migrateIfNecessary(_ sourceURL: URL) throws
      {
        // Get the metadata for the current persistent store
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: sourceURL)

        // Note the index of the current schema version for convenience
        let currentIndex = schemaVersions.count - 1

        // Find the index of the most-recent compatible schema version
        guard var sourceIndex = schemaVersions.lastIndex(where: {$0.managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)})
          else { throw Exception("no compatible schema version") }

        // Perform a sequence of incremental migrations from the stored schema version to the current schema version...
        while sourceIndex < currentIndex {
          // Source is the schema corresponding to the (possibly updated) persistent store.
          let source = schemaVersions[sourceIndex]

          // Determine the index of the next version which does not support lightweight migration.
          let indexOrNil = schemaVersions[sourceIndex + 1 ... currentIndex].firstIndex {$0.supportsLightweightMigration == false}

          // The migration is lightweight iff the calculated index is not i+1.
          let lightweight = indexOrNil != .some(sourceIndex + 1)

          // The index of the target schema depends on whether or not a lightweight migration exists.
          let targetIndex = lightweight ? (indexOrNil.map({$0 - 1}) ?? currentIndex) : sourceIndex + 1
          let target = schemaVersions[targetIndex]

          // If necessary, establish a temporary URL to serve as the target for heavyweight migration.
          let targetURL = lightweight ? sourceURL : URL.temporaryDirectory.appending(components: sourceURL.lastPathComponent)

          // Calculate the mapping model
          let migration = lightweight
            ? try NSMappingModel.inferredMappingModel(forSourceModel: source.managedObjectModel, destinationModel: target.managedObjectModel)
            : try target.customMigration(from: source)

          // Perform the migration.
          log("performing \(lightweight ? "inferred" : "custom") migration of \(source.name) from \(source.version) to \(target.version)")
          let manager = NSMigrationManager(sourceModel: source.managedObjectModel, destinationModel: target.managedObjectModel)
          try manager.migrateStore(from: sourceURL, type: .sqlite, options: [:], mapping: migration, to: targetURL, type: .sqlite, options: [:])

          // Move the target store overtop of the source store if necessary
          if sourceURL != targetURL {
            try FileManager.default.moveItem(at: targetURL, to: sourceURL)
          }

          // Update the index indicating the stored model
          sourceIndex = targetIndex
        }

        assert(sourceIndex == currentIndex)
      }


    public var schema : Schema
      { schemaVersions.last! }


    public func create<T: Object>(_ type: T.Type = T.self, initialize: (T) throws -> Void) throws -> T
      {
        guard let entity = schema.entitiesByName[type.entityName] else { throw Exception("unknown entity \(type.entityName)") }
        let instance = type.init(entity: entity.entityDescription, insertInto: managedObjectContext)
        try initialize(instance)
        return instance
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
