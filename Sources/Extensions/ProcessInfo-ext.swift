/*

*/

import Foundation


extension ProcessInfo
  {
    public var argumentsByName : [String: String]
      {
        Dictionary(uniqueKeysWithValues: arguments.dropFirst().compactMap { arg in
          let components = arg.components(separatedBy: "=")
          guard components.count == 2 else { return nil }
          return (components[0], components[1])
        })
      }
  }
