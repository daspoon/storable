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
    static func getStoredPropertyInfo(from decl: DeclSyntaxProtocol) throws -> StoredPropertyInfo
      {
        guard let vdecl = decl.as(VariableDeclSyntax.self), let info = vdecl.storedPropertyInfo else {
          throw Exception("@\(attributeName) is only applicable to stored properties")
        }
        guard case .none = vdecl.modifiers?.contains(where: {$0.name.trimmed.description == "override"}) else {
          throw Exception("@\(attributeName) is incompatible with override")
        }
        return info
      }

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
