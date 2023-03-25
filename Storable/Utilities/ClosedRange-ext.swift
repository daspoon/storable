/*

  Created by David Spooner

*/

//
//extension ClosedRange
//  {
//    /// Return true iff the receiving range contains the given range.
//    public func contains(_ other: Self) -> Bool
//      { contains(other.lowerBound) && contains(other.upperBound) }
//  }
//

extension ClosedRange where Bound == Int
  {
    /// Convenience method for defining the range of a to-one relationship
    public static var toOne : Self
      { 1 ... 1 }

    /// Convenience method for defining the range of a to-one relationship
    public static var toOptional : Self
      { 0 ... 1 }

    /// Convenience method for defining the range of a to-one relationship
    public static var toMany : Self
      { 0 ... .max }
  }
