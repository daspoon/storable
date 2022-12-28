/*

*/

import CoreData


extension NSRelationshipDescription
  {
    public var rangeOfCount : ClosedRange<Int>
      {
        get { minCount ... maxCount }
        set { minCount = newValue.lowerBound; maxCount = newValue.upperBound }
      }
  }
