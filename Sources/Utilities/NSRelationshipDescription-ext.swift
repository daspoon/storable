/*

  Created by David Spooner

*/

import CoreData


extension NSRelationshipDescription
  {
    /// Get or set the minimum and maximum object counts as a range of integers.
    public var rangeOfCount : ClosedRange<Int>
      {
        get { minCount ... maxCount }
        set { minCount = newValue.lowerBound; maxCount = newValue.upperBound }
      }
  }
