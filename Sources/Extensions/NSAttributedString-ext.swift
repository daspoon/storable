/*

*/

import UIKit


extension NSAttributedString
  {
    public static func + (lhs: NSAttributedString, rhs: NSAttributedString) -> NSAttributedString
      {
        let result = NSMutableAttributedString()
        result.append(lhs)
        result.append(rhs)
        return result
      }

    public static func + (lhs: NSAttributedString, rhs: String) -> NSAttributedString
      { lhs + NSAttributedString(string: rhs) }

    public convenience init(string s: String, font: UIFont, color: UIColor)
      { self.init(string: s, attributes: [.font: font, .foregroundColor: color]) }
  }


extension Array where Element == NSAttributedString
  {
    public func joined(separator: NSAttributedString) -> Element
      {
        let result = NSMutableAttributedString()
        for (i, element) in self.enumerated() {
          if i > 0 {
            result.append(separator)
          }
          result.append(element)
        }
        return result
      }
  }
