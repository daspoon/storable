/*

  Created by David Spooner.

*/

import Foundation


extension Notification.Name
  {
    /// Posted by DataStore when a requested save operation fails. The notification object is the posting DataStore instance, and the userInfo dictionary associates the generated NSError to the key *"error"*.
    public static var dataStoreSaveDidFail : Self
      { .init("xyz.lambdasoftware.storable.dataStoreSaveDidFail") }
  }
