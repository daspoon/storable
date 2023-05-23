/*

  Created by David Spooner

*/

import Foundation


extension CodingUserInfoKey
  {
    public static var dataStore : CodingUserInfoKey
      { .init(rawValue: "xyz.lambdasoftware.Storable.dataStore")! }
  }
