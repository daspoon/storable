/*

*/

import CoreData


/// Represents a step in the migration process.

enum MigrationStep
  {
    /// Perform a lightweight migration to the associated model.
    case lightweight(NSManagedObjectModel)

    /// Run the given script. This step requires the ScriptMarker entity exists in the object model of the affected store.
    case script((NSManagedObjectContext) throws -> Void)


    /// Apply the migration step to the given store URL of the given object model and return the object model of the updated content.
    func apply(to sourceURL: URL, of sourceModel: NSManagedObjectModel) throws -> NSManagedObjectModel
      {
        switch self {
          case .lightweight(let targetModel) :
            // Infer the mapping model, perform the migration and return the target model.
            let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: targetModel)
            let manager = NSMigrationManager(sourceModel: sourceModel, destinationModel: targetModel)
            try manager.migrateStore(from: sourceURL, type: .sqlite, mapping: mapping, to: sourceURL, type: .sqlite)
            return targetModel

          case .script(let script) :
            // Open the store
            let coordinator = NSPersistentStoreCoordinator(managedObjectModel: sourceModel)
            let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
            context.persistentStoreCoordinator = coordinator
            _ = try coordinator.addPersistentStore(type: .sqlite, at: sourceURL)
            // Fetch an instance of the marker entity; if none exists, run the script, add a marker instance, and save the context.
            if try context.tryFetchObject(makeFetchRequest(for: MigrationScriptMarker.self)) == nil {
              try script(context)
              try context.create(MigrationScriptMarker.self) { _ in }
              try context.save()
            }
            // Return the source model
            return sourceModel

          /*
          case .heavyweight(let target, let mappingModel) :
            // Establish a temporary URL to host the modified store.
            let targetURL = URL.temporaryDirectory.appending(components: sourceURL.lastPathComponent)
            // Perform the migration.
            let manager = NSMigrationManager(sourceModel: source, destinationModel: target)
            try manager.migrateStore(from: sourceURL, type: .sqlite, options: [:], mapping: migration, to: targetURL, type: .sqlite, options: [:])
            // Move the target store overtop of the source store
            try FileManager.default.moveItem(at: targetURL, to: sourceURL)
          */
        }
      }
  }


extension MigrationStep : CustomStringConvertible
  {
    var description : String
      {
        switch self {
          case .lightweight : return "performing lightweight migration"
          case .script : return "script"
        }
      }
  }


extension Array where Element == MigrationStep
  {
    /// Eliminate consecutive lightweight steps.
    var compacted : [MigrationStep]
      {
        var compacted : [MigrationStep] = []
        var lightweightStep : MigrationStep?
        for step in self {
          switch step {
            case .lightweight :
              lightweightStep = step
            default :
              lightweightStep.map { compacted.append($0) }
              lightweightStep = nil
              compacted.append(step)
          }
        }
        lightweightStep.map { compacted.append($0) }
        return compacted
      }
  }
