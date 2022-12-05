/*

*/

import CoreData


extension NSRelationshipDescription
  {
    var rangeOfCount : ClosedRange<Int>
      {
        get { minCount ... maxCount }
        set { minCount = newValue.lowerBound; maxCount = newValue.upperBound }
      }
  }
