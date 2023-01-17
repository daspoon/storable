/*

*/

import Foundation


extension NSObject
  {
    /// Return the sequence of classes between given descendant and ancestor classes, inclusive.
    public static func inheritanceChain<Root: NSObject>(from descendant: Root.Type, to ancestor: Root.Type = Root.self, includingDescendant: Bool = true, includingAncestor: Bool = true) -> AnyIterator<Root.Type>
      {
        var next = includingDescendant ? descendant : (descendant.superclass() as? Root.Type)
        return AnyIterator {
          defer { next = next?.superclass() as? Root.Type }
          return includingAncestor || next != .some(ancestor) ? next : nil
        }
      }
  }
