/*

  Created by David Spooner

*/

import CoreData


/// FetchedPropertyInfo maintains the data required to define a fetched property on a subclass of Entity; it is analogous to CoreData's NSFetchedPropertyDescription.

public struct FetchedPropertyInfo : PropertyInfo
  {
    public let name : String
    public let fetchRequest : NSFetchRequest<NSFetchRequestResult>

    public init<T: NSFetchRequestResult>(name: String, fetchRequest: NSFetchRequest<T>)
      {
        self.name = name
        self.fetchRequest = fetchRequest as! NSFetchRequest<NSFetchRequestResult>
      }
  }
