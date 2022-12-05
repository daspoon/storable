/*

*/


extension String
  {
    public static func space(_ n: Int) -> String
      { .init(repeating: " ", count: n) }

    /// Return an approximate plural form by appending "s"
    var pluralized : String
      { self + "s" }

    /// Return an approximate camel-cased form by lowercasing the first character.
    var camelCased : String
      { String(prefix(1)).lowercased() + String(dropFirst(1)) }
  }
