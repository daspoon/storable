/*

  Created by David Spooner

*/

import Foundation


extension ProcessInfo
  {
    func argument(forKey key: String) -> String?
      {
        for arg in arguments {
          guard arg.hasPrefix(key + "=") else { continue }
          return arg.removing(prefix: key + "=")
        }
        return nil
      }
  }
