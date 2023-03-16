/*

  Created by David Spooner

*/

import SwiftSyntax


extension TypeSyntaxProtocol
  {
    var longName : String
      {
        switch self.as(OptionalTypeSyntax.self) {
          case .some(let optional) :
            return "Optional<\(optional.wrappedType.description)>"
          case .none :
            return self.description
        }
      }
  }
