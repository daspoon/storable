/*

*/

extension Sequence
  {
    /// Return a sequence whose elements are the pairs of adjacent elements of the receiver, preserving order.
    public var adjacentPairs : AnySequence<(left: Element, right: Element)>
      {
        var iterator = self.makeIterator()
        var pending = iterator.next()
        return AnySequence(AnyIterator {
          guard let left = pending, let right = iterator.next() else { return nil }
          defer { pending = right }
          return (left, right)
        })
      }
  }
