/*

*/

import UIKit


extension UITextField
  {
    public var returnKeyEnabled : Bool
      {
        get { value(forKeyPath: "inputDelegate.returnKeyEnabled") as? Bool ?? false }
        set { setValue(newValue, forKeyPath: "inputDelegate.returnKeyEnabled") }
      }
  }
