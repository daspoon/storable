/*

*/

import Foundation


extension Array
  {
    /// Assuming the receiver is sorted, return a pair (exists, index) indicating whether the given element exists and the index where it exists or should be inserted.
    public func sortedIndexForElement<Key>(_ key: Key, usingComparator compare: (Key, Element) -> ComparisonResult) -> (exists:Bool, index:Int)
      {
        var remaining = NSMakeRange(0, self.count)
        while remaining.length > 0 {
          let i = remaining.location + remaining.length / 2
          switch compare(key, self[i]) {
            case .orderedAscending : // <
              remaining = NSMakeRange(remaining.location, i - remaining.location)
            case .orderedSame : // ==
              return (exists:true, index:i)
            case .orderedDescending : // >
              remaining = NSMakeRange(i + 1, remaining.length - (i - remaining.location) - 1)
          }
        }
        return (exists:false, index:remaining.location)
      }

    /// Assuming the reciever is sorted, insert the given element at an appropriate index.
    public mutating func sortedInsert(_ element: Element, usingComparator compare: (Element, Element) -> ComparisonResult)
      {
        let (_, index) = sortedIndexForElement(element, usingComparator: compare)
        insert(element, at: index)
      }
  }
