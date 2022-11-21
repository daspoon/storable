/*

*/


extension Collection
  {
    public var only : Element?
      { count == 1 ? self[self.startIndex] : nil }
  }
