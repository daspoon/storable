/*

*/

import UIKit


extension NSLayoutConstraint
  {
    public class func constraintsWithOptions(_ options: NSLayoutConstraint.FormatOptions = [], metrics: [String: NSNumber]? = nil, views: [String: AnyObject], visualFormatStrings formats: [String]) -> [NSLayoutConstraint]
      {
        var constraints:[NSLayoutConstraint] = []
        for format in formats {
          constraints = constraints + NSLayoutConstraint.constraints(withVisualFormat: format, options: options, metrics: metrics, views: views)
        }
        return constraints
      }
  }


extension NSLayoutConstraint.Axis
  {
    public var opposite : NSLayoutConstraint.Axis
      {
        switch self {
          case .horizontal : return .vertical
          case .vertical : return .horizontal
          default :
            log("unexpected case: \(self)")
            return self
        }
      }
  }
