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
      }


    private func migrateIfNecessary(_ storeURL: URL) throws
      {
        // Get the metadata for the current persistent store
        let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(type: .sqlite, at: storeURL)

        // Find the index of the most-recent compatible schema version
        guard let index = schemaVersions.lastIndex(where: {$0.managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)})
          else { throw Exception("no compatible schema version") }

        // Perform incremental migration between adjacent model versions
        for (prev, next) in schemaVersions.suffix(from: index).adjacentPairs {
          log("migrating \(prev.name) from \(prev.version) to \(next.version)")
          guard let lightweight = try? NSMappingModel.inferredMappingModel(forSourceModel: prev.managedObjectModel, destinationModel: next.managedObjectModel)
            else { throw Exception("no inferred mapping model between versions \(prev.version) and \(next.version)") }
          let manager = NSMigrationManager(sourceModel: prev.managedObjectModel, destinationModel: next.managedObjectModel)
          try manager.migrateStore(from: storeURL, type: .sqlite, options: [:], mapping: lightweight, to: storeURL, type: .sqlite, options: [:])
        }
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


    public func fetchObjects<T: Object>(_ request: NSFetchRequest<T>) throws -> [T]
      { return try managedObjectContext.fetch(request) }

    public func fetchObject<T: Object>(_ request: NSFetchRequest<T>) throws -> T
      {
        let results = try fetchObjects(request)
        switch results.count {
          case 1 :
            return results[0]
          case 0 :
          throw Exception("no \(String(describing: request.entityName)) instance satisfying '\(String(describing: request.predicate))'")
          default :
          throw Exception("multiple \(String(describing: request.entityName)) instances satisfying '\(String(describing: request.predicate))'")
        }
      }

    public func fetchObjects<T: Object>(of type: T.Type = T.self, satisfying predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [T]
      { try fetchObjects(makeFetchRequest(for: type, predicate: predicate, sortDescriptors: sortDescriptors)) }

    public func fetchObject<T: Object>(of type: T.Type = T.self, satisfying predicate: NSPredicate) throws -> T
      { try fetchObject(makeFetchRequest(for: type, predicate: predicate)) }


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
