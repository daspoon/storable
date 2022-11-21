/*

*/

import CoreData


@objc(Confidant)
class Confidant : NSManagedObject
  {
    struct Advancement : Codable
      {
        let rank : String // Note: string-typed to accommodate Friendship vs Romance
        let unlock : GameDate?
        let trigger : String?
        let prerequisite : String?
        let restriction : String?
        let dialogue : [String]?
        let bonus : String?
        let note : String?

        init(info: [String: Any]) throws
          {
            rank = try info.requiredValue(for: "rank")
            unlock = try info.optionalValue(for: "unlock") { parseGameDate($0) }
            trigger = try info.optionalValue(for: "trigger")
            prerequisite = try info.optionalValue(for: "prerequisite")
            restriction = try info.optionalValue(for: "restriction")
            dialogue = try info.optionalValue(for: "dialogue")
            bonus = try info.optionalValue(for: "bonus")
            note = try info.optionalValue(for: "note")
          }
      }

    struct Hangout : Codable
      {
        var venue : String
        var available : GameDateRange?
        var requirement : String?
        var bonus : String?
        var dialog : [String]?

        init(info: [String: Any]) throws
          {
            venue = try info.requiredValue(for: "venue")
            available = try info.optionalValue(for: "available") { parseGameDateRange($0) }
            requirement = try info.optionalValue(for: "requirement")
            bonus = try info.optionalValue(for: "bonus")
            dialog = try info.optionalValue(of: [String].self, for: "dialog")
          }
      }

    struct Talent : Codable
      {
        let rank : Int
        let name : String
        let effect : String

        init(info: [String: Any]) throws
          {
            rank = try info.requiredValue(for: "rank")
            name = try info.requiredValue(for: "name")
            effect = try info.requiredValue(for: "effect")
          }
      }


    @NSManaged var name : String
    @NSManaged var arcanum : Arcana
    @NSManaged var persona : Persona?
    @NSManaged var location : String?
    @NSManaged var unlock : GameDate
    @NSManaged var rank : String?
    @NSManaged var talentData : Data
    @NSManaged var advancementData : Data
    @NSManaged var hangoutData : Data
    @NSManaged var gifts : Set<Gift>

    var talents : [Talent] = []
    var advancements : [Advancement] = []
    var hangouts : [Hangout] = []


    convenience init(for raceName: String, info: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        name = try info.requiredValue(for: "name")
        arcanum = try context.race(named: raceName)
        persona = try info.optionalValue(for: "persona") { try context.demon(named: $0) }
        location = try info.optionalValue(for: "location")
        unlock = try info.requiredValue(for: "unlock") { parseGameDate($0) }
        talents = try info.requiredValue(for: "talents") { (dicts: [[String: Any]]) in try dicts.map { try Talent(info: $0) } }
        advancements = try info.requiredValue(for: "progression") { (dicts: [[String: Any]]) in try dicts.map { try Advancement(info: $0) } }
        hangouts = try info.optionalValue(for: "hangouts", transformedBy: {(dicts: [[String: Any]]) in try dicts.map {try Hangout(info: $0)}}) ?? []

        talentData = try JSONEncoder().encode(talents)
        advancementData = try JSONEncoder().encode(advancements)
        hangoutData = try JSONEncoder().encode(hangouts)
      }


    override func awakeFromFetch()
      {
        super.awakeFromFetch()

        talents = try! JSONDecoder().decode([Talent].self, from: talentData)
        advancements = try! JSONDecoder().decode([Advancement].self, from: advancementData)
        hangouts = try! JSONDecoder().decode([Hangout].self, from: hangoutData)
      }
  }
