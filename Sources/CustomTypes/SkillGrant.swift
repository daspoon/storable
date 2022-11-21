/*

*/

import CoreData


@objc(SkillGrant)
class SkillGrant : NSManagedObject
  {
    @NSManaged var skill : Skill
    @NSManaged var wielder : Combatant
    @NSManaged var level : Int
  }


extension SkillGrant : Comparable
  {
    static func < (lhs: SkillGrant, rhs: SkillGrant) -> Bool
      { lhs.level < rhs.level || (lhs.level == rhs.level && lhs.skill.name < rhs.skill.name) }
  }
