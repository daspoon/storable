/*

*/

import UIKit


extension UIResponder
  {
    public func enclosingResponder<T: UIResponder>(ofType: T.Type) -> T?
      {
        var responder = self
        while let enclosing = responder.next {
          if let target = enclosing as? T {
            return target
          }
          responder = enclosing
        }
        return nil
      }
  }
