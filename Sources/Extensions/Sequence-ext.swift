/*

*/


extension Sequence
  {
    public func crossProduct<S: Sequence>(_ other: S) -> AnySequence<(Element, S.Element)>
      {
        AnySequence( self.lazy.flatMap { x in other.lazy.map { y in (x, y) }})
      }
  }
