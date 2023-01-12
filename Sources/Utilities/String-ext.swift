/*

*/


extension String
  {
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
  }