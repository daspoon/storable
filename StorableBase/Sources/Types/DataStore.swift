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


    /// Return the managed object model, or nil if the persistent store is not open.
    public var managedObjectModel : NSManagedObjectModel!
      { state?.managedObjectModel }


    /// Return the managed object context, or nil if the persistent store is not open.
    public var managedObjectContext : NSManagedObjectContext!
      { state?.managedObjectContext }


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

        // Observe the optional notification to request saving the main context.
        let saveRequestObservation = saveRequestNotificationName.map { name in NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in self.save() }
        }

        // Retain the required state.
        state = .init(
          managedObjectModel: model,
          managedObjectContext: context,
          persistentStore: store,
          saveRequestObservation: saveRequestObservation
        )
      }


    /// Open the store with the object model for the given schema. If the schema has previous versions, those versions must be provided as the migrations parameter ordered from oldest to newest.
    public func openWith(schema: Schema, migrations: [Migration] = []) throws
      {
        // Determine the list of schema version identifiers from oldest to newest and ensure each is distinct.
        let versionIds = (migrations.map({$0.source}) + [schema]).reduce((1, []), { (accum: (idx: Int, ids: [String]), schema: Schema) -> (idx: Int, ids: [String]) in
          (accum.idx + (schema.versionId == nil ? 1 : 0), accum.ids + [schema.versionId ?? "\(accum.idx)"])
        }).ids
        guard Set(versionIds).count == versionIds.count else { throw Exception("version identifiers must be distinct") }

        // Create the object model for the current schema.
        let info = try schema.createRuntimeInfo(withVersionId: versionIds.last!)

        // If the store exists and is incompatible with the target schema, then perform incremental migration from the previously compatible schema.
        if FileManager.default.fileExists(atPath: storeURL.path) {
          let metadata = try getMetadata()
          if info.managedObjectModel.isConfiguration(withName: nil as String?, compatibleWithStoreMetadata: metadata) == false {
            // First pair each migration with the version identifier of its schema; note that zip drops trailing element of versionIds
            let pairs = Array(zip(migrations, versionIds))
            // Get the compatible model for the metadata along with the list of steps leading to the target model
            let path = try Self.migrationPath(from: metadata, to: (schema, info.managedObjectModel), using: pairs)
            // Iteratively perform the migration steps on the persistent store, passing along the updated store model
            _ = try path.migrationSteps.reduce(path.sourceModel) { (sourceModel, migrationStep) in
              log("\(migrationStep)")
              return try migrate(from: sourceModel, using: migrationStep)
            }
          }
        }

        // Retain the entity lookup table
        classInfoByName = info.classInfoByName

        // Defer to super to open the store
        try openWith(model: info.managedObjectModel)
      }


    /// Perform each of the given ingestion methods, taking JSON data from the given source.
    public func ingest(from source: IngestSource, methods: [IngestMethod]) throws
      {
        precondition(state != nil, "not open")

        // Perform each method, allowing closures to be registered for delayed execution.
        var delayedEffects : [() throws -> Void] = []
        for method in methods {
          log("ingesting \(method.methodIdentifier) data" + (method.resourceKeyPath.map {" from " + $0} ?? ""))
          let json : Any
          switch method.resourceKeyPath?.decomposeKeyPath() {
            case .none :
              json = [:]
            case .some((let key, let suffix)) :
              let data = try source.jsonData(for: key)
              json = try JSONSerialization.load(from: data, context: key, keyPath: suffix)
          }
          try method.ingest(json, into: self, delay: {delayedEffects.append($0)})
        }

        // Perform the delayed closures
        for effect in delayedEffects {
          try effect()
        }
      }


    public func classInfo(for entityName: String) throws -> ClassInfo
      {
        guard let info = classInfoByName[entityName] else { throw Exception("unknown entity name '\(entityName)'") }
        return info
      }


    /// Save the managed object context's changes to the persistent store. Invoke the given block, if any, on the main queue upon completion.
    public func save(onCompletion: ((Error?) -> Void)? = nil)
      {
        guard let state else { preconditionFailure("not open") }

        do {
          try state.managedObjectContext.save()
          onCompletion?(nil)
        }
        catch {
          log("save failed: \(error)")
          NotificationCenter.default.post(name: .dataStoreSaveDidFail, object: self, userInfo: [
            "error": error as NSError,
          ])
          onCompletion?(error)
        }
      }


    /// Close the persistent store, discarding any outstanding changes.
    public func close() throws
      {
        guard let state else { preconditionFailure("not open") }

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


    /// Return the list of steps required to migrate a store from the previous version.
    static func migrationPath(from metadata: [String: Any], to current: (schema: Schema, model: NSManagedObjectModel), using versions: [(Migration, String)]) throws -> (sourceModel: NSManagedObjectModel, migrationSteps: [Migration.Step])
      {
        // If the current model matches the given metadata then we're done
        guard current.model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false
          else { return (current.model, []) }

        // Otherwise there must be a previous schema version...
        guard let (migration, versionId) = versions.last
          else { throw Exception("no compatible schema version") }

        // to determine the source model and sequence of initial steps recursively.
        let previousSchema = migration.source
        let previousModel = try previousSchema.createRuntimeInfo(withVersionId: versionId).managedObjectModel
        let initialPath = try Self.migrationPath(from: metadata, to: (previousSchema, previousModel), using: versions.dropLast(1))

        // Append the additional steps required to migrate between the previous and current version.
        let additionalSteps = try current.schema.migrationSteps(to: current.model, from: previousModel, of: previousSchema, using: migration)
        return (previousModel, initialPath.migrationSteps + additionalSteps)
      }


    /// Apply the migration step to the store content and return the object model for the updated content. It is assumed store content is consistent with the given object model.
    func migrate(from storeModel: NSManagedObjectModel, using step: Migration.Step) throws -> NSManagedObjectModel
      {
        switch step {
          case .lightweight(let targetModel) :
            // Perform a lightweight migration
            try migrate(from: storeModel, to: targetModel)
            return targetModel

          case .script(let script, let idempotent) :
            try update(as: storeModel) { context in
              // If an instance of ScriptMarker doesn't exist, run the script, add a marker instance, and save the context.
              if try context.tryFetchObject(fetchRequest(for: Migration.ScriptMarker.self)) == nil || idempotent {
                try script(context)
                try context.create(Migration.ScriptMarker.self) { _ in }
                try context.save()
              }
            }
            return storeModel
        }
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
  }
