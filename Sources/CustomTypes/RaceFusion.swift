/*

*/

import CoreData


@objc(RaceFusion)
class RaceFusion : NSManagedObject
  {
    @NSManaged var index : Int
    @NSManaged var output : Arcana
    @NSManaged var inputs : Set<Arcana>


    convenience init(index: Int, output: Arcana, inputs: Set<Arcana>, context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.output = output
        self.inputs = inputs
      }
  }
