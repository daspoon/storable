/*

*/

import Foundation


extension Character
  {
    /// Return the unicode scalar representation, or nil if the character is composed of multiple unicode scalars.
    public var unicodeScalar : Unicode.Scalar?
      { unicodeScalars.count == 1 ? unicodeScalars[unicodeScalars.startIndex] : nil }
  }
