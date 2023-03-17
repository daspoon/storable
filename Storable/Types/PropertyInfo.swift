/*

  Created by David Spooner

*/

import Foundation


/// The PropertyInfo enum unifies the types which serve as managed property descriptors.

public enum PropertyInfo
  {
    case attribute(Attribute)
    case relationship(Relationship)
    case fetched(Fetch)
  }
