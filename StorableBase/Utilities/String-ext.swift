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

    /// Return the concatenation of a number of newline characters, defaulting to 1.
    public static func newline(_ n: Int = 1) -> String
      { .init(repeating: "\n", count: n) }

    /// Return the concatenation of a number of space characters, defaulting to 1.
    public static func space(_ n: Int) -> String
      { .init(repeating: " ", count: n) }

    /// Return a copy of the receiver with each non-initial line prefixed by the given number of space characters.
    public func indented(_ n: Int) -> String
      { components(separatedBy: String.newline()).joined(separator: .newline() + .space(n)) }
  }
