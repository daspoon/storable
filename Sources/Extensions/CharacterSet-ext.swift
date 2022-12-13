/*

*/


import Foundation


extension CharacterSet
  {
    /// Return true iff the receiver contains the given character, which must be represented by a single unicode scalar.
    public func contains(_ character: Character) -> Bool
      {
        guard let unicodeScalar = character.unicodeScalar else { return false }
        return self.contains(unicodeScalar)
      }
  }
