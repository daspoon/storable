/*

*/

import CoreData


@objc(Skill)
class Skill : NSManagedObject, Named
  {
    @NSManaged var name : String
    @NSManaged var element : Element
    @NSManaged var cost : Int32
    @NSManaged var effect : String
    @NSManaged var unique : String?
      // the name of the persona to which this skill is unique

    @NSManaged var card : String?
    @NSManaged var grants : Set<SkillGrant>
    @NSManaged var bearer : Persona?
    @NSManaged var itemizations : Set<Itemization>


    convenience init(name: String, attributes: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        self.name = name
        self.effect = try attributes.requiredValue(for: "effect")
        self.element = try attributes.requiredValue(for: "element") { context.configuration.element(for: $0) }
        self.cost = try attributes.optionalValue(for: "cost") ?? 0
        self.unique = try attributes.optionalValue(for: "unique")
        self.card = try attributes.optionalValue(for: "card")
      }


    var formattedCost : String?
      {
        // TODO: make this a feature of the configuration...
        guard cost > 0 else { return nil }
        #if true // p5r
        let info : (value: Int32, isPercentage: Bool) = cost < 100 ? (cost, true) : (cost - 1000, false)
        #else // p5
        let info : (value: Int32, isPercentage: Bool) = cost < 100 ? (cost, true) : (cost - 1000, false)
        #endif
        return "\(info.value)" + (info.isPercentage ? "% hp" : " sp")
      }
  }

