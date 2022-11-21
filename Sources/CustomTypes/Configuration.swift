/*

*/

import CoreData
import UIKit


@objc(Configuration)
class Configuration : NSManagedObject
  {
    @NSManaged var baseStats : String
    @NSManaged var resistNames : String
    @NSManaged var resistElems : String
    @NSManaged var skillElems : String
    @NSManaged var affinityElems : String?
    @NSManaged var gameDate : GameDate


    convenience init(info: [String: Any], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        baseStats = try info.requiredValue(for: "baseStats") { (names: [String]) in names.joined(separator: ",") }

        resistElems = try info.requiredValue(for: "resistElems") { (names: [String]) in names.joined(separator: ",") }
        skillElems = try info.requiredValue(for: "skillElems") { (names: [String]) in names.joined(separator: ",") }
        affinityElems = try info.optionalValue(for: "affinityElems") { (names: [String]) in names.joined(separator: ",") }

        // Note: unfortunately the keys of resisCodes are arbitrarily ordered, and reconsructing the presentation order
        resistNames = try info.requiredValue(for: "resistCodes") { (table: [String: Int]) in
          table.sorted(by: {$0.value > $1.value}).map({$0.key}).joined(separator: "")
        }

        gameDate = minGameDate
      }


    func indexOf(element: Element) -> Int
      { elements.firstIndex(of: element)! }

    func indexOf(ability: Ability) -> Int
      { abilities.firstIndex(of: ability)! }


    func element(for name: String) -> Element?
      { elements.contains(name) ? name : nil }

    func resistance(for char: Character) -> Resistance?
      { resistanceCharacters.contains(char) ? char : nil }


    // TODO: the following should be transient attributes...

    var abilities : [Ability]
      { baseStats.components(separatedBy: ",") }

    var resistanceCharacters : [Character]
      { Array(self.resistNames) }

    var resistanceElements : [String]
      { self.resistElems.components(separatedBy: ",") }

    var skillElements : [String]
      { self.skillElems.components(separatedBy: ",") }

    var affinityElements : [String]?
      { self.affinityElems?.components(separatedBy: ",") }

    var elements : [String]
      { return resistanceElements + skillElements + (affinityElements ?? []) }


    // The following should be defined by subclasses...

    func iconInfoForResistanceElement(_ element: Element) -> (imageName: String, tintColor: UIColor)
      {
        switch element {
          case "phys", "phy"  : return ("hand.raised.fill", .secondaryLabel)
          case "gun"   : return ("circle.fill", .secondaryLabel)
          case "fire", "fir"  : return ("flame.fill", .red)
          case "ice"   : return ("snowflake", .cyan)
          case "wind", "for"  : return ("wind", .green)
          case "elec", "ele"  : return ("bolt.fill", .yellow)
          case "psy"   : return ("brain", .secondaryLabel)
          case "nuke"  : return ("dot.radiowaves.up.forward", .secondaryLabel)
          case "bless", "lig" : return ("sun.max.fill", .secondaryLabel)
          case "curse", "dar" : return ("cloud.moon.rain", .secondaryLabel)
          default :
            return ("questionmark", .secondaryLabel)
        }
      }


    func elementsIncompatible(with element: Element?) -> Set<Element>
      {
        guard let element else { return [] }
        // TODO: use comp-config data
        let table : [String: Set<String>] = [
          "almighty" : [],
          "phys" : ["fire", "ice", "elec", "wind", "psy", "nuke", "bless", "curse", "almighty"],
          "gun" : ["fire", "ice", "elec", "wind", "psy", "nuke", "bless", "curse", "almighty"],
          "fire" : ["ice"],
          "ice" : ["fire"],
          "elec" : ["wind"],
          "wind" : ["elec"],
          "psy" : ["nuke"],
          "nuke" : ["psy"],
          "bless" : ["ailment", "curse", "gun", "phys"],
          "curse" : ["bless", "healing", "gun", "phys"],
          "ailment" : ["bless", "healing"],
          "healing" : ["curse", "gun", "phys"],
          "passive" : [],
          "support" : [],
        ]
        return table[element]!
      }
  }
