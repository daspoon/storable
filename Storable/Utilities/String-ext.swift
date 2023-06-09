/*

  Created by David Spooner

*/


extension String
  {
    /// Return a copy of the receiver after removing the given prefix and suffix, when they exist.
    public func removing(prefix p: String? = nil, suffix s: String? = nil) -> String
      {
        var trimmed = self

        if let prefix = p, let range = trimmed.range(of: prefix, options:.anchored) {
          trimmed = String(trimmed[range.upperBound ..< trimmed.endIndex])
        }

        if let suffix = s, let range = trimmed.range(of: suffix, options: [.anchored, .backwards]) {
          trimmed = String(trimmed[trimmed.startIndex ..< range.lowerBound])
        }

        return trimmed
      }


    /// Assuming the receiver is a key path, return the first element together with the remaining string. Returns (self, nil) if the specified separator (defaulting to ".") does not occur in the receiver.
    public func decomposeKeyPath(separator: String = ".") -> (key: String, suffix: String?)
      {
        guard let range = range(of: separator) else { return (self, nil) }
        return (
          key: String(self[startIndex ..< range.lowerBound]),
          suffix: String(self[range.upperBound ..< endIndex])
        )
      }
  }
