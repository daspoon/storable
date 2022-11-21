/*

*/

import CoreData


@objc(Crossword)
class Crossword : NSManagedObject
  {
    @NSManaged var index : Int
    @NSManaged var question : String
    @NSManaged var answer : String

    convenience init(info: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.index = try info.requiredValue(for: "#")
        self.question = try info.requiredValue(for: "Q")
        self.answer = try info.requiredValue(for: "A")
      }
  }
