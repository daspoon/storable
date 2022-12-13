/*

*/


extension String
  {
    /// Return the concatenation of a number of newline characters, defaulting to 1.
    public static func newline(_ n: Int = 1) -> String
      { .init(repeating: "\n", count: n) }

    /// Return the concatenation of a number of space characters, defaulting to 1.
    public static func space(_ n: Int) -> String
      { .init(repeating: " ", count: n) }

    /// Return a copy of the receiver with each non-initial line prefixed by the given number of space characters.
    public func indented(_ n: Int) -> String
      { components(separatedBy: String.newline()).joined(separator: .newline() + .space(n)) }

    /// Return an approximate plural form by appending "s"
    var pluralized : String
      { self + "s" }

    /// Return an approximate camel-cased form by lowercasing the first character.
    var camelCased : String
      { String(prefix(1)).lowercased() + String(dropFirst(1)) }
  }
