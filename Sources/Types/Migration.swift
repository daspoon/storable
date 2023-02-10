/*

*/

import CoreData


/// A structure representing a transition from a source schema to an (implicit) target schema, along with an optional method to perform an in-place update of a persistent store as part of a custom migration process.

public struct Migration
  {
    /// A function to perform in-place update of a persistent store.
    public typealias Script = (NSManagedObjectContext) throws -> Void

    /// ScriptMarker defines an entity which appears in the intermediate model of a custom migration; an instance of this entity indicates the script has run to completion.
    @objc class ScriptMarker : Object {}

    /// A step in a migration process.
    public enum Step
      {
        /// Perform a lightweight migration to the associated model.
        case lightweight(NSManagedObjectModel)

        /// Run the given script. This step requires the ScriptMarker entity exists in the object model of the affected store.
        case script(Script)
      }


    /// The schema/model of the persistent stores to which this migration applies.
    var source : Schema

    /// The optional in-place update used in a custom migration.
    let script : Migration.Script?


    public init(from s: Schema, using f: Migration.Script? = nil)
      {
        source = s
        script = f
      }
  }


extension Migration.Step
  {
    /// Apply the migration step to the given store URL of the given object model and return the object model of the updated content.
    func apply(to sourceURL: URL, of sourceModel: NSManagedObjectModel) throws -> NSManagedObjectModel
      {
        switch self {
          case .lightweight(let targetModel) :
            // Perform a lightweight migration
            try BasicStore.migrateStore(at: sourceURL, from: sourceModel, to: targetModel)
            return targetModel

          case .script(let script) :
            try BasicStore.updateStore(at: sourceURL, as: sourceModel) { context in
              // If an instance of ScriptMarker doesn't exist, run the script, add a marker instance, and save the context.
              if try context.tryFetchObject(makeFetchRequest(for: Migration.ScriptMarker.self)) == nil {
                try script(context)
                try context.create(Migration.ScriptMarker.self) { _ in }
                try context.save()
              }
            }
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


extension Migration.Step : CustomStringConvertible
  {
    public var description : String
      {
        switch self {
          case .lightweight : return "performing lightweight migration"
          case .script : return "script"
        }
      }
  }
