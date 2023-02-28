/*

*/

import CoreData


/// DataStore creates and maintains a persistent store for an object model generated from a given Schema.

public class DataStore : BasicStore
  {
    /// Map entity names to pairs of EntityInfo and NSEntityDescription.
    public private(set) var classInfoByName : [String: Schema.ClassInfo] = [:]


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
        try super.openWith(model: info.managedObjectModel)
      }


    public func openWith(schema: Schema, stateEntityName: String = "State", dataSource: DataSource, migrations: [Migration] = []) throws
      {
        try openWith(schema: schema, migrations: migrations)

        // Ensure the State entity is defined and as has a single instance.
        guard let stateInfo = classInfoByName[stateEntityName] else { throw Exception("Entity '\(stateEntityName)' is not defined") }
        guard case .singleton = stateInfo.managedObjectClass.identity else { throw Exception("Entity '\(stateEntityName)' must have a single instance") }

        // Retrieve the configuration if one exists; otherwise trigger ingestion from the data source.
        var configurations = try managedObjectContext.fetch(NSFetchRequest<Entity>(entityName: stateEntityName))
        switch configurations.count {
          case 1 :
            break
          case 0 :
            try IngestContext.populate(dataStore: self, from: dataSource)
            configurations = try managedObjectContext.fetch(NSFetchRequest<Entity>(entityName: stateEntityName))
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

        classInfoByName = [:]
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
              if try context.tryFetchObject(makeFetchRequest(for: Migration.ScriptMarker.self)) == nil || idempotent {
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
