/*

*/

import CoreData


@objc(Combatant)
class Combatant : NSManagedObject
  {
    @NSManaged var name : String
    @NSManaged var level : Int16
    @NSManaged var baseStatData : Data
    @NSManaged var resists : String
    @NSManaged var skillGrants : Set<SkillGrant>


    var baseStatValues : [Int16] = []


    func value(for ability: Ability) -> Int16
      {
        let index = DataModel.shared.configuration.indexOf(ability: ability)
        return self.baseStatValues[index]
      }


    func resistance(for element: Element) -> Resistance
      {
        let index = DataModel.shared.configuration.indexOf(element: element)
        let chars = Array(resists)
        return chars[index]
      }


    // NSManagedObject

    override func awakeFromFetch()
      {
        super.awakeFromFetch()

        baseStatValues = try! JSONDecoder().decode([Int16].self, from: self.baseStatData)
      }
  }
