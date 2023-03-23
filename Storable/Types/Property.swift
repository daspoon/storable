/*

  Created by David Spooner

*/

import Foundation


/// The Property enum unifies the types which serve as managed property descriptors.

public enum Property
  {
    case attribute(Attribute)
    case relationship(Relationship)
    case fetched(Fetched)
  }
