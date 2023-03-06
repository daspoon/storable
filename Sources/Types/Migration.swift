/*

  Created by David Spooner

*/

import CoreData


/// Migration represents a transition from an associated schema (source) to an implicit evolution of that schema (target).
/// Each instance has an optional procedure run as part of an the migration process between (the models of) the source to target schema;
/// its purpose being to ensure the store content is compatible with both source and target models.

public struct Migration
  {
    /// A function to perform in-place update of a persistent store.
    public typealias Script = (NSManagedObjectContext) throws -> Void

    /// ScriptMarker defines an entity which appears in the intermediate model of a custom migration; an instance of this entity indicates the script has run to completion.
    @objc class ScriptMarker : Entity {}

    /// A step in a migration process.
    public enum Step
      {
        /// Perform a lightweight migration to the associated model.
        case lightweight(NSManagedObjectModel)

        /// Run the given script. The second element indicates whether or not the script can be run repeatedly.
        case script(Script, Bool)
      }


    /// The schema/model of the persistent stores to which this migration applies.
    var source : Schema

    /// The optional in-place update used in a custom migration.
    let script : Migration.Script?

    /// Indicates whether or not the script can be run repeatedly without adverse effect.
    let idempotent : Bool


    public init(from s: Schema, idempotent i: Bool = false, using f: Migration.Script? = nil)
      {
        source = s
        script = f
        idempotent = i
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
