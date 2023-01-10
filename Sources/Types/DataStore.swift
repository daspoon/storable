/*

*/

import CoreData


public class DataStore
  {
    let schema : Schema
    let managedObjectModel : NSManagedObjectModel
    public let managedObjectContext : NSManagedObjectContext


    public init(schema s: Schema, reset: Bool) throws
      {
        schema = s

        // Construct the managed object model and the mapping of entity names to info required for instance creation.
        managedObjectModel = schema.managedObjectModel

        // Create the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        // Determine the location of the data store
        let applicationDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let dataStoreURL = URL(string: "\(schema.name).sqlite", relativeTo: applicationDocumentsURL)!

        // Optionally delete the data store (for debugging)
        if reset && FileManager.default.fileExists(atPath: dataStoreURL.path) {
          try FileManager.default.removeItem(at: dataStoreURL)
        }

        // Open the data store, migrating if necessary
        _ = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dataStoreURL, options: [
          NSMigratePersistentStoresAutomaticallyOption: true,
          NSInferMappingModelAutomaticallyOption: true,
        ])

        // Create and configure the managed object context
        managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

        // Observe notifications to trigger saving changes
        NotificationCenter.default.addObserver(self, selector: #selector(save(_:)), name: .dataStoreNeedsSave, object: nil)
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
            try IngestContext.populate(schema: schema, managedObjectContext: managedObjectContext, dataSource: dataSource)
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


    func create<T: Object>(_ type: T.Type = T.self, initialize: (T) throws -> Void) throws -> T
      {
        guard let entity = schema.entitiesByName[type.entityName] else { throw Exception("unknown entity \(type.entityName)") }
        let instance = type.init(entity: entity.entityDescription, insertInto: managedObjectContext)
        try initialize(instance)
        return instance
      }


    @objc
    func save(_ sender: Any? = nil)
      {
        do {
          try managedObjectContext.save()
        }
        catch let error as NSError {
          log("failed to save: \(error)")
        }
      }
  }
