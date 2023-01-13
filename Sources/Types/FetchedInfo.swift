/*

*/

import CoreData


public struct FetchedInfo : PropertyInfo
  {
    public let name : String
    public let fetchRequest : NSFetchRequest<NSFetchRequestResult>

    public init<T: NSFetchRequestResult>(name: String, fetchRequest: NSFetchRequest<T>)
      {
        self.name = name
        self.fetchRequest = fetchRequest as! NSFetchRequest<NSFetchRequestResult>
      }
  }
