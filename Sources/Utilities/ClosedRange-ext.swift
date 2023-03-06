/*

  Created by David Spooner

*/


extension ClosedRange
  {
    /// Return true iff the receiving range contains the given range.
    public func contains(_ other: Self) -> Bool
      { contains(other.lowerBound) && contains(other.upperBound) }
  }
