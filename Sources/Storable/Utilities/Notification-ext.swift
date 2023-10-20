/*

  Created by David Spooner.

*/

import Foundation


extension Notification.Name
  {
    /// Posted in response to an exception raised within *NSMangedObject*'s extension method *performSave(completion:)*. The notification's *object* is the *NSManagedObjectContext* instance whose *save* method failed, and its *userInfo* associates the raised *NSError* to the key *"error"*.
    public static var dataStoreSaveDidFail : Self
      { .init("xyz.lambdasoftware.storable.dataStoreSaveDidFail") }
  }
