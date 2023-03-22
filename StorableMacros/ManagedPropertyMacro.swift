/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// ManagedPropertyMacro defines the common features of macro types used to declare managed properties.
protocol ManagedPropertyMacro : AccessorMacro
  {
    /// The name of the macro attribute.
    static var attributeName : String { get }

    /// Return the textual expression of a managed property descriptor for the given variable declaration and macro attribute.
    static func generateDescriptorText(for declaration: StoredPropertyInfo, using attribute: AttributeSyntax) throws -> String
  }


extension ManagedPropertyMacro
  {
    /// Ensure the given declaration corresponds to a stored property compatible with macro application and return the relevant associated information.
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

    /// Used to generate propagate specified macro arguments as arguments to a generated property descriptor expression.
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
