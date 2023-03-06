/*

  Created by David Spooner

*/

import Foundation


/// Custom Notification names used within this package.

extension Notification.Name
  {
    /// The notification name used to signal that DataStore instance should save changes...
    public static var dataStoreNeedsSave : Self
      { .init("com.lambda.masquerade.dataStoreNeedsSaveNotification") }
  }
