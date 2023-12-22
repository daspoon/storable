/*

  Created by David Spooner

*/


extension ClosedRange
  {
    /// Return true iff the receiving range contains the given range.
    public func contains(_ other: Self) -> Bool
      { contains(other.lowerBound) && contains(other.upperBound) }

    /// Clamp the given value to this range if necessary.
    public func clamp(_ value: Bound) -> Bound
      {
        guard value >= lowerBound else { return lowerBound }
        guard value <= upperBound else { return upperBound }
        return value
      }
  }


extension ClosedRange where Bound : FloatingPoint
  {
    /// Return the value at the given offset/ratio.
    public subscript (_ offset: Bound) -> Bound
      {
        guard upperBound != lowerBound else { return .nan }
        return lowerBound + offset * (upperBound - lowerBound)
      }

    /// Return the offset/ratio at which the given value lies.
    public func offset(of value: Bound) -> Bound
      {
        guard upperBound != lowerBound else { return .nan }
        return (value - lowerBound) / (upperBound - lowerBound)
      }
  }


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
