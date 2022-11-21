/*

*/

import CoreData


@objc(Itemization)
class Itemization : NSManagedObject
  {
    @objc enum Kind : Int16
      {
        case skill
        case item
      }

    @NSManaged var kind : Kind
    @NSManaged var rare : Bool
    @NSManaged var persona : Persona
    @NSManaged var skill : Skill!
    @NSManaged var itemName : String!

    var name : String
      { kind == .skill ? (skill?.name ?? "skill == nil") : (itemName ?? "itemName == nil") }
  }


extension Itemization : Comparable
  {
    static func < (lhs: Itemization, rhs: Itemization) -> Bool
      {
        if lhs.rare != rhs.rare { return (lhs.rare ? 1 : 0) < (rhs.rare ? 1 : 0) }
        return lhs.name < rhs.name
      }
  }
