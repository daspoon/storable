/*

*/

import CoreData


@objc(GiftEffect)
class GiftEffect : NSManagedObject
  {
    @NSManaged var gift : Gift
    @NSManaged var confidant : Confidant
    @NSManaged var bonus : Int
  }
