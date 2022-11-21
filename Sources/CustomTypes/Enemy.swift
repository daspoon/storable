/*

*/

import CoreData


@objc(Enemy)
class Enemy : Combatant
  {
    @NSManaged var areas : String?
    @NSManaged var armor : String?
    @NSManaged var card : String?
    @NSManaged var drops : String?
    @NSManaged var persona : String?
    @NSManaged var race : String?
    @NSManaged var trait : String
    @NSManaged var material : String?


    convenience init(name: String, attributes: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.name = name
        self.areas = try attributes.optionalValue(for: "areas")
        self.armor = try attributes.optionalValue(for: "armor")
        self.card = try attributes.optionalValue(for: "card")
        self.drops = try attributes.optionalValue(for: "drops") { (strings: [String]) in strings.joined(separator: ", ") }
        self.level = try attributes.requiredValue(for: "lvl")
        self.material = try attributes.optionalValue(for: "material")
        self.persona = try attributes.requiredValue(for: "persona")
        self.race = try attributes.requiredValue(for: "race")
        self.resists = try attributes.requiredValue(for: "resists")
        self.trait = try attributes.requiredValue(for: "trait")

        baseStatValues = try attributes.optionalValue(for: "stats") ?? []
        let statCount = context.configuration.abilities.count
        if baseStatValues.count < statCount {
          baseStatValues.append(contentsOf: Array(repeating: baseStatValues.last ?? 0, count: statCount - baseStatValues.count))
        }
        self.baseStatData = try! JSONEncoder().encode(baseStatValues)

        let skillNames : [String] = try attributes.optionalValue(for: "skills") ?? []
        for skillName in skillNames {
          let grant = SkillGrant(entity: try context.entity(for: SkillGrant.self), insertInto: context.managedObjectContext)
          grant.skill = try context.skill(named: skillName)
          grant.wielder = self
          grant.level = 0
        }
      }
  }
