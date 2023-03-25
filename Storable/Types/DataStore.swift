/*

  Created by David Spooner

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore
  {
    /// The location of the persistent store established on initialization.
    public let storeURL : URL

    /// The persistent store type, currently fixed as sqlite.
    public let storeType : NSPersistentStore.StoreType = .sqlite

    /// The optional notification name observed to trigger implicit saving while open.
    public let saveRequestNotificationName : Notification.Name?

    /// The state maintained while the persistent store is open.
    private var state : State?
    struct State
      {
        let managedObjectModel : NSManagedObjectModel
        let managedObjectContext : NSManagedObjectContext
        let persistentStore : NSPersistentStore
        let saveRequestObservation : NSObjectProtocol?
      }

    /// The mapping of entity names to ClassInfo structures which maintain their metadata.
    public private(set) var classInfoByName : [String: ClassInfo] = [:]


    /// Create an instance with the given name in the given directory, which defaults to the application's document directory.
    public required init(name: String = "store", directoryURL specifiedURL: URL? = nil, saveRequestNotificationName: Notification.Name? = nil)
      {
        guard let directoryURL = specifiedURL ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last
          else { fatalError("failed to get URL for document directory") }

        guard let storeURL = URL(string: "\(name).sqlite", relativeTo: directoryURL) else { fatalError("failed to create relative URL") }

        self.storeURL = storeURL
        self.saveRequestNotificationName = saveRequestNotificationName
      }


    /// Implicitly close the store on deallocation.
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


    /// Open the persistent store for the given object model, which must be compatible.
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
          saveRequestObservation: saveRequestNotificationName.map { name in NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { self.performSave($0) }
          }
        )
      }


    /// Open the store with the object model for the given schema.
    public func openWith(schema: Schema) throws
      {
        // Create the object model for the current schema.
        let info = try schema.createRuntimeInfo()

        // Retain the entity lookup table
        classInfoByName = info.classInfoByName

        // Defer to super to open the store
        try openWith(model: info.managedObjectModel)
      }


    public func classInfo(for entityName: String) throws -> ClassInfo
      {
        guard let info = classInfoByName[entityName] else { throw Exception("unknown entity name '\(entityName)'") }
        return info
      }


    public func fetchObject<T: ManagedObject>(id name: String, of type: T.Type = T.self) throws -> T
      {
        try managedObjectContext.fetchObject(makeFetchRequest(for: type, predicate: .init(format: "name = %@", name)))
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


    /// Override super's close method to reset the mapping of entity names to ClassInfo instances.
    /// Close the persistent store, either saving or discarding the changes to the managed object context; the default is to save changes.
    public func close(savingChanges: Bool = true) throws
      {
        guard let state else { preconditionFailure("not open") }

        if state.managedObjectContext.hasChanges, savingChanges {
          try state.managedObjectContext.save()
        }

        try state.persistentStore.persistentStoreCoordinator?.remove(state.persistentStore)

        self.state = nil

        classInfoByName = [:]
      }


    /// Delete the persistent store if it exists. The store must not be open.
    public func reset() throws
      {
        precondition(state == nil, "store is open")

        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        try FileManager.default.removeItem(at: storeURL)
      }
  }
