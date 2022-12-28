/*

*/

import CoreData


public class DataStore
  {
    let schema : Schema
    let managedObjectModel : NSManagedObjectModel
    public let managedObjectContext : NSManagedObjectContext

    public private(set) static var shared : DataStore!
    private static let semaphore = DispatchSemaphore(value: 1)


    public init(schema s: Schema, stateEntityName: String = "State", dataSource: DataSource, reset: Bool) throws
      {
        // Ensure the State entity is defined and as has a single instance.
        guard let stateEntity = s.entitiesByName[stateEntityName] else { throw Exception("Entity '\(stateEntityName)' is not defined") }
        guard stateEntity.hasSingleInstance else { throw Exception("Entity '\(stateEntityName)' must have a single instance") }

        Self.semaphore.wait()
        precondition(Self.shared == nil)

        schema = s

        // Construct the managed object model and the mapping of entity names to info required for instance creation.
        managedObjectModel = schema.managedObjectModel

        // Create the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

        // Determine the location of the data store
        let applicationDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
        let dataStoreURL = URL(string: "dataStore.sqlite", relativeTo: applicationDocumentsURL)!

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

        // Retrieve the configuration if one exists; otherwise trigger ingestion from the data source.
        var configurations = try managedObjectContext.fetch(NSFetchRequest<Object>(entityName: schema.stateEntityName))
        switch configurations.count {
          case 1 :
            break
          case 0 :
            try IngestContext.populate(schema: schema, managedObjectContext: managedObjectContext, dataSource: dataSource)
            configurations = try managedObjectContext.fetch(NSFetchRequest<Object>(entityName: schema.stateEntityName))
            guard configurations.count == 1 else {
              throw Exception("inconsistency after ingestion: \(configurations.count) configurations detected")
            }
          default :
            throw Exception("inconsistency on initialization: \(configurations.count) configurations detected")
        }

        Self.shared = self
        Self.semaphore.signal()
      }
  }
