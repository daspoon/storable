/*

*/

import Foundation


extension Scanner
  {
    /// Attempt to scan an identifier, with the leading characters taken from one set (defaulting to letters) and the remaining characters taken from another (defaulting to alphanumerics).
    public func scanIdentifier(leadingCharacters: CharacterSet = .letters, remainingCharacters: CharacterSet = .alphanumerics) -> String?
      { scanCharacters(from: leadingCharacters).map { $0 + (scanCharacters(from: remainingCharacters) ?? "") } }
  }

