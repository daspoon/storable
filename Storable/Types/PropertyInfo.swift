/*

  Created by David Spooner

*/

import Foundation


/// The PropertyInfo protocol unifies the types which serve as custom managed property descriptors.

public protocol PropertyInfo
  {
    /// The name of the managed object property. Required.
    var name : String { get }

    /// The name of the property in the previous entity version, if necessary. This method should return non-nil iff the property exists in the previous entity with a different name. The default implementation returns nil.
    var renamingIdentifier : String? { get }
  }


extension PropertyInfo
  {
    public var renamingIdentifier : String?
      { nil }
  }
