/*

*/

import Foundation


extension String
  {
    public func removingPrefix(_ prefix: String) -> String
      {
        guard let range = self.range(of: prefix, options:.anchored) else { return self }
        return String(self[range.upperBound ..< self.endIndex])
      }

    public func removingSuffix(_ suffix: String) -> String
      {
        guard let range = self.range(of: suffix, options: [.anchored, .backwards]) else { return self }
        return String(self[startIndex ..< range.lowerBound])
      }

    public func replacingCharactersIn(_ nsrange: NSRange, with replacement: String) -> String
      {
        guard let range = Range(nsrange, in: self) else { preconditionFailure("invalid argument") }
        return String(self[..<range.lowerBound]) + replacement + String(self[range.upperBound...])
      }
  }
