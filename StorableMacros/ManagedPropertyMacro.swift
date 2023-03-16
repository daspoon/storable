/*

  Created by David Spooner

*/

import SwiftSyntax


protocol ManagedPropertyMacro
  {
    static var attributeName : String { get }

    static func generateDescriptorText(for declaration: StoredPropertyInfo, using attribute: AttributeSyntax) throws -> String
  }


extension ManagedPropertyMacro
  {
    static func generateDescriptorArgumentText(for argument: AttributeSyntax.Argument?, withInitialComma: Bool) -> String
      {
        guard case .some(.argumentList(let elements)) = argument else { return "" }
        var result = ""
        for (i, element) in elements.enumerated() {
          if i > 0 || withInitialComma {
            result += ", "
          }
          result += "\(element.label.map({$0}) ?? "")\(element.colon.map({$0}) ?? "")\(element.expression)"
        }
        return result
      }
  }
