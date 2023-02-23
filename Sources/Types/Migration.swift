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
