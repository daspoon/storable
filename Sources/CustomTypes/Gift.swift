/*

*/

import CoreData


@objc(Gift)
class Gift : NSManagedObject
  {
    @NSManaged var name : String
    @NSManaged var store : String
    @NSManaged var area : String
    @NSManaged var price : Int
    @NSManaged var recipient : Confidant?


    convenience init(name: String, info: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.name = name
        self.store = try info.requiredValue(for: "store")
        self.area = try info.requiredValue(for: "area")
        self.price = try info.requiredValue(for: "price")
      }
  }
