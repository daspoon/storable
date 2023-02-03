/*

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore
  {
    public let managedObjectContext : NSManagedObjectContext
    public let managedObjectModel : NSManagedObjectModel
    public let entityInfoByName : [String: EntityInfo]


    public init(schema: Schema, priorVersions: [Schema] = [], reset: Bool = false) throws
      {
        // Retain the schema's object model.
        let schemaInfo = try schema.createRuntimeInfo()
        managedObjectModel = schemaInfo.managedObjectModel
        entityInfoByName = schemaInfo.entityInfoByName

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
          // Get the metadata for the persistent store
          let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: dataStoreURL)

          // Get the model for the given metadata along with the list of steps required to migrate the store to the current object model.
          let path = try Self.migrationPath(toStoreMetadata: metadata, from: (schema, managedObjectModel), previousVersions: priorVersions)

          // Iteratively perform the migration steps on the persistent store, passing along the store model
          _ = try path.migrationSteps.compacted.reduce(path.sourceModel) { (sourceModel, migrationStep) in
            log("\(migrationStep)")
            return try migrationStep.apply(to: dataStoreURL, of: sourceModel)
          }
        }

        // Open the persistent store
        _ = try persistentStoreCoordinator.addPersistentStore(type: .sqlite, at: dataStoreURL)

        // Observe notifications to trigger saving changes
        NotificationCenter.default.addObserver(self, selector: #selector(performSave(_:)), name: .dataStoreNeedsSave, object: nil)
      }


    public convenience init(schema: Schema, priorVersions: [Schema] = [], stateEntityName: String = "State", dataSource: DataSource, reset: Bool) throws
      {
        // Defer to the designated initializer
        try self.init(schema: schema, priorVersions: priorVersions, reset: reset)

        // Ensure the State entity is defined and as has a single instance.
        guard let stateInfo = entityInfoByName[stateEntityName] else { throw Exception("Entity '\(stateEntityName)' is not defined") }
        guard case .singleton = stateInfo.objectInfo.managedObjectClass.identity else { throw Exception("Entity '\(stateEntityName)' must have a single instance") }

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


    /// Return the list of steps required to migrate a store from the previous version.
    static func migrationPath(toStoreMetadata metadata: [String: Any], from current: (schema: Schema, model: NSManagedObjectModel), previousVersions: [Schema]) throws -> (sourceModel: NSManagedObjectModel, migrationSteps: [MigrationStep])
      {
        // If the current model matches the given metadata then we're done
        guard current.model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false
          else { return (current.model, []) }

        // Otherwise there must be a previous schema version...
        guard let previousSchema = previousVersions.last
          else { throw Exception("no compatible schema version") }

        // to determine the source model and sequence of initial steps recursively.
        let previousModel = try previousSchema.createRuntimeInfo().managedObjectModel
        let initialPath = try Self.migrationPath(toStoreMetadata: metadata, from: (previousSchema, previousModel), previousVersions: previousVersions.dropLast(1))

        // Append the additional steps required to migrate between the previous and current version.
        let additionalSteps = try current.schema.migrationSteps(from: previousModel, of: previousSchema, to: current.model)
        return (previousModel, initialPath.migrationSteps + additionalSteps)
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
