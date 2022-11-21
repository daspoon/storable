/*

*/

import CoreData


@objc(Persona)
class Persona : Combatant
  {
    @objc enum Category : Int16
      {
        case normal = 0
        case rare = 1
        case special = 2
        case dlc = 3
        case party = 4
      }


    @NSManaged var arcana : Arcana
    @NSManaged var category : Category
    @NSManaged var inherits : Element?
    @NSManaged var trait : Skill?
    @NSManaged var accessible : Bool // true for non-dlc and owned dlc
    @NSManaged var captured : Bool
    @NSManaged var itemizations : Set<Itemization>
    @NSManaged var index : Int
    @NSManaged var fusionsToProduce : Set<Fusion>
    

    convenience init(name: String, attributes: [String: Any], category: Category, context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.name = name
        self.index = context.allocateDemonIndex()
        self.arcana = try attributes.requiredValue(for: "race") { try context.race(named: $0) }
        self.category = category
        self.accessible = category != .dlc && category != .party
        self.level = try attributes.requiredValue(for: "lvl")
        self.inherits = try attributes.optionalValue(for: "inherits") { context.configuration.element(for: $0) }
        self.trait = try attributes.optionalValue(for: "trait") { try context.skill(named: $0) }

        self.baseStatValues = try attributes.requiredValue(for: "stats")
        self.baseStatData = try! JSONEncoder().encode(baseStatValues)

        self.resists = try attributes.requiredValue(for: "resists")

        let skillInfo: [String: Int] = try attributes.requiredValue(for: "skills")
        for (skillName, grantedAtLevel) in skillInfo {
          let grant = SkillGrant(entity: try context.entity(for: SkillGrant.self), insertInto: context.managedObjectContext)
          grant.skill = try context.skill(named: skillName)
          grant.wielder = self
          grant.level = grantedAtLevel
        }

        for key in ["item", "itemr"] {
          guard let name: String = try attributes.optionalValue(for: key) else { continue }
          let itemization = Itemization(entity: try context.entity(for: Itemization.self), insertInto: context.managedObjectContext)
          itemization.persona = self
          itemization.rare = key == "itemr"
          if let skill = try? context.dataModel.findObject(of: Skill.self, named: name) {
            itemization.kind = .skill
            itemization.skill = skill
          }
          else {
            itemization.kind = .item
            itemization.itemName = name
          }
        }
      }


    var rare : Bool
      { category == .rare }


    var summonCost : Int
      {
        // TODO: make this accurate for both base and current build...
        return 1000 * Int(level)
      }


    var estimatedFusionCost : Int
      {
        return summonCost * 2
      }
  }
