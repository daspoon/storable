/*

*/

import Foundation


extension NSSortDescriptor
  {
    public static func with(keyPaths: [String], ascending: Bool = true) -> [NSSortDescriptor]
      {
        var array : [NSSortDescriptor] = []
        for keyPath in keyPaths {
          array.append(NSSortDescriptor(key: keyPath, ascending: ascending))
        }
        return array
      }
  }
