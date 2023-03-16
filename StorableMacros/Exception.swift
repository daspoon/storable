/*

  Created by David Spooner

*/


internal enum Exception : Error, CustomStringConvertible
  {
    case message(String)

    init(_ text: String)
      { self = .message(text) }

    var description : String {
      guard case .message(let text) = self else { fatalError() }
      return text
    }
  }
