/*

*/

import CoreData


public class BasicStore
  {
    /// The location of the persistent store established on initialization.
    public let storeURL : URL


    /// The state maintained while the persistent store is open.
    private var state : State?
    struct State
      {
        let managedObjectModel : NSManagedObjectModel
        let managedObjectContext : NSManagedObjectContext
        let persistentStore : NSPersistentStore
        let saveRequestObservation : NSObjectProtocol
      }


    /// Create an instance with the given name. The location of the persistent store is determined by the application's document directory.
    public required init(name: String = "store")
      {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else { fatalError("failed to get URL for document directory") }
        guard let storeURL = URL(string: "\(name).sqlite", relativeTo: documentsURL) else { fatalError("failed to create relative URL") }

        self.storeURL = storeURL
      }


    deinit
      {
        guard state != nil else { return }

        do { try close() }
        catch let error {
          log("failed to close \(storeURL): \(error)")
        }
      }


    /// Return true iff the persistent store is open.
    public var isOpen : Bool
      { state != nil }


    /// Return the managed object context, or nil if the persistent store is not open.
    public var managedObjectContext : NSManagedObjectContext!
      {
        guard let state else { return nil }
        return state.managedObjectContext
      }


    /// Open the persistent store for the given object model, which must be compatible; any necessary migration must be performed prior to invoking this method.
    public func openWith(model: NSManagedObjectModel) throws
      {
        precondition(state == nil, "already open")

        // Create the persistent store coordinator and managed object context.
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator

        // Open the persistent store, which must be compatible with the given object model.
        let store = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)

        // Retain the
        state = .init(
          managedObjectModel: model,
          managedObjectContext: context,
          persistentStore: store,
          saveRequestObservation: NotificationCenter.default.addObserver(forName: .dataStoreNeedsSave, object: nil, queue: .main) { self.performSave($0) }
        )
      }


    /// Save the managed object context's changes to the persistent store.
    public func save() throws
      {
        guard let state else { throw Exception("store is not open: \(storeURL)") }

        try state.managedObjectContext.save()
      }


    /// Save the managed object context's changes to the persistent store.
    @objc public func performSave(_ sender: Any? = nil)
      {
        do { try save() }
        catch let error as NSError {
          log("failed to save: \(error)")
        }
      }


    public func close(savingChanges: Bool = true) throws
      {
        guard let state else { preconditionFailure("not open") }

        if state.managedObjectContext.hasChanges, savingChanges {
          try state.managedObjectContext.save()
        }

        try state.persistentStore.persistentStoreCoordinator?.remove(state.persistentStore)

        self.state = nil
      }


    /// Delete the persistent store if it exists. The store must not be open.
    public func reset() throws
      {
        precondition(state == nil, "store is open")

        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        try FileManager.default.removeItem(at: storeURL)
      }


    /// Perform lightweight migration of the store between the given object models. The store must not be open.
    public func migrate(from sourceModel: NSManagedObjectModel, to targetModel: NSManagedObjectModel) throws
      {
        guard state == nil else { preconditionFailure("store is open") }
        try Self.migrateStore(at: storeURL, from: sourceModel, to: targetModel)
      }


    /// Open the store with the given object model, invoke the given script, and save.
    public func update(as objectModel: NSManagedObjectModel, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        guard state == nil else { preconditionFailure("store is open") }
        try Self.updateStore(at: storeURL, as: objectModel, using: script)
      }


    /// Perform lightweight migration of the specified store between the given object models. The store must not be open.
    public static func migrateStore(at storeURL: URL, from sourceModel: NSManagedObjectModel, to targetModel: NSManagedObjectModel) throws
      {
        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: targetModel)
        let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: targetModel)
        try manager.migrateStore(from: storeURL, type: .sqlite, mapping: mapping, to: storeURL, type: .sqlite)
      }


    /// Open the specified store with the given object model, invoke the given script, and save.
    public static func updateStore(at storeURL: URL, as objectModel: NSManagedObjectModel, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: objectModel)
        _ = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        try script(context)
        try context.save()
      }
  }
