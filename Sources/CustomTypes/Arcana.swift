/*

*/

import CoreData


@objc(Arcana)
class Arcana : NSManagedObject
  {
    @NSManaged var name : String
    @NSManaged var confidant : Confidant?
    @NSManaged var members : Set<Persona>
    @NSManaged var reverseFusions : Set<RaceFusion>

    convenience init(name: String, context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.name = name
      }
  }
