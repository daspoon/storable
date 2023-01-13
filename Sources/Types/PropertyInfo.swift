/*

*/

import Foundation


/// The PropertyInfo protocol unifies the types which serve as custom managed property descriptors.

public protocol PropertyInfo
  {
    /// The name of the managed object property. Required.
    var name : String { get }
  }
