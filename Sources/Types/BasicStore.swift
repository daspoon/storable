/*

*/

import CoreData


public class BasicStore
  {
    /// The location of the persistent store established on initialization.
    public let storeURL : URL
    public let storeType : NSPersistentStore.StoreType = .sqlite


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


    /// Return the metadata identifying the object model with which the persistent store was created, assuming it exists.
    func getMetadata() throws -> [String: Any]
      { try NSPersistentStoreCoordinator.metadataForPersistentStore(type: storeType, at: storeURL) }


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
        let store = try coordinator.addPersistentStore(type: storeType, at: storeURL)

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
    public func migrate(from storeModel: NSManagedObjectModel, to targetModel: NSManagedObjectModel) throws
      {
        precondition(isOpen == false && isCompatible(with: storeModel))

        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: storeModel, destinationModel: targetModel)
        let manager = NSMigrationManager(sourceModel: storeModel, destinationModel: targetModel)
        try manager.migrateStore(from: storeURL, type: storeType, mapping: mapping, to: storeURL, type: storeType)
      }


    /// Open the store with the given object model, invoke the given script, and save.
    public func update(as storeModel: NSManagedObjectModel, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        precondition(isOpen == false && isCompatible(with: storeModel))

        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: storeModel)
        let store = try coordinator.addPersistentStore(type: storeType, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        try script(context)
        try context.save()
        try coordinator.remove(store)
      }


    /// Check compatibility of the given object model with the persistent store, assuming it exists. Don't propagate exceptions as this method exists only to enforce the expectation of compatibility.
    func isCompatible(with model: NSManagedObjectModel) -> Bool
      {
        let metadata : [String: Any]
        do { metadata = try getMetadata() }
        catch {
          log("failed to get store metadata: \(error)")
          return false
        }
        return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
      }
  }
