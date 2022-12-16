/*

*/

import Foundation


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


    /// Return the string which results from removing all consecutive characters of the given set from both ends of the receiver.
    public func trimming(_ chars: CharacterSet) -> SubSequence?
      {
        // find the indices of the first and last non-whitespace characters
        switch (firstIndex {!chars.contains($0)}, lastIndex {!chars.contains($0)}) {
          case (.none, .none) :
            return nil
          case (.some(let lb), .some(let ub)) :
            return self[lb ... ub]
          default :
            fatalError("improbable case")
        }
      }


    /// Eliminate whitespace lines which preceed either a '}' or eof.
    func compressingVerticalWhitespace() -> String
      {
        return components(separatedBy: String.newline()).reduce((lines: [String](), blanks: [String]()), { total, line in
          // Trim whitespace and get the leading character (if any) from the remnant
          switch line.trimming(.whitespaces)?.first {
            case .none : // line is blank; add it to the buffer
              return (total.lines, total.blanks + [line])
            case .some("}") : // line closes a scope; discarding buffered blanks and concatenate line to the result
              return (total.lines + [line], [])
            case .some(_) : // line is non-blank; concatenate both buffered blank lines and line to the result
              return (total.lines + total.blanks + [line], [])
          }
        }).lines.joined(separator: .newline())
      }


    /// Return the constituent words of a bumpy-case string.
    public var bumpyCaseComponents : [String]
      {
        var components : [String] = []

        var i = startIndex
        let n = endIndex
        while i < n {
          let word: String

          // Determine the number (i - j) of leading uppercase characters...
          let j = i
          while i < n && self[i].isUppercase { i = index(after: i) }

          // If this number is greater than one, treat the substring as an acronym...
          if i > index(after: j) {
            // If the sequence is non-terminal then its last letter is considered the first letter of the subsequent word.
            if i < n { i = index(before: i) }
            word = String(self[j ..< i])
          }
          else {
            let c = self[j].isUppercase ? self[j].lowercased() : String(self[j])
            while i < n && !self[i].isUppercase { i = index(after: i) }
            word = c + String(self[index(after: j) ..< i])
          }

          components.append(word)
        }

        return components
      }
  }
