/*

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore : BasicStore
  {
    /// Map entity names to pairs of ObjectInfo and NSEntityDescription.
    public private(set) var entityInfoByName : [String: EntityInfo] = [:]


    public func openWith(schema: Schema, migrations: [Migration] = []) throws
      {
        // Create the object model for the current schema; the model incorporates the schema version number into its hash.
        let info = try schema.createRuntimeInfo()

        // If the store exists and is incompatible with the target schema, then perform incremental migration from the previously compatible schema.
        if FileManager.default.fileExists(atPath: storeURL.path) {
          let metadata = try getMetadata()
          if info.managedObjectModel.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false {
            // Get the compatible model for the metadata along with the list of steps leading to the target model
            let path = try Self.migrationPath(fromStoreMetadata: metadata, to: (schema, info.managedObjectModel), migrations: migrations)
            // Iteratively perform the migration steps on the persistent store, passing along the updated store model
            _ = try path.migrationSteps.reduce(path.sourceModel) { (sourceModel, migrationStep) in
              log("\(migrationStep)")
              return try migrate(from: sourceModel, using: migrationStep)
            }
          }
        }

        // Retain the entity lookup table
        entityInfoByName = info.entityInfoByName

        // Defer to super to open the store
        try super.openWith(model: info.managedObjectModel)
      }


    public func openWith(schema: Schema, stateEntityName: String = "State", dataSource: DataSource, migrations: [Migration] = []) throws
      {
        try openWith(schema: schema, migrations: migrations)

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


    public override func close(savingChanges save: Bool = true) throws
      {
        try super.close(savingChanges: save)

        entityInfoByName = [:]
      }


    /// Return the list of steps required to migrate a store from the previous version.
    static func migrationPath(fromStoreMetadata metadata: [String: Any], to current: (schema: Schema, model: NSManagedObjectModel), migrations: [Migration]) throws -> (sourceModel: NSManagedObjectModel, migrationSteps: [Migration.Step])
      {
        // If the current model matches the given metadata then we're done
        guard current.model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata) == false
          else { return (current.model, []) }

        // Otherwise there must be a previous schema version...
        guard let migration = migrations.last
          else { throw Exception("no compatible schema version") }

        // to determine the source model and sequence of initial steps recursively.
        let previousSchema = migration.source
        let previousModel = try previousSchema.createRuntimeInfo().managedObjectModel
        let initialPath = try Self.migrationPath(fromStoreMetadata: metadata, to: (previousSchema, previousModel), migrations: migrations.dropLast(1))

        // Append the additional steps required to migrate between the previous and current version.
        let additionalSteps = try current.schema.migrationSteps(to: current.model, from: previousModel, of: previousSchema, using: migration.script)
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

          case .script(let script) :
            try update(as: storeModel) { context in
              // If an instance of ScriptMarker doesn't exist, run the script, add a marker instance, and save the context.
              if try context.tryFetchObject(makeFetchRequest(for: Migration.ScriptMarker.self)) == nil {
                try script(context)
                try context.create(Migration.ScriptMarker.self) { _ in }
                try context.save()
              }
            }
            return storeModel
        }
      }


    @available(*, unavailable, message: "Use openWith(schema:migrations:) instead")
    public override func openWith(model: NSManagedObjectModel) throws
      { preconditionFailure("unavailable") }
  }
