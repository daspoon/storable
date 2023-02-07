/*

*/


extension ClosedRange
  {
    public func contains(_ other: Self) -> Bool
      { contains(other.lowerBound) && contains(other.upperBound) }
  }
