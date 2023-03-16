/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct RelationshipMacro  : AccessorMacro, ManagedPropertyMacro
  {
    static var attributeName : String { "Relationship" }

    static func generateDescriptorText(for decl: StoredPropertyInfo, using attribute: AttributeSyntax) throws -> String
      {
        return ".relationship(.init(name: \"\(decl.name)\", type: \(decl.type.longName).self"
          + generateDescriptorArgumentText(for: attribute.argument, withInitialComma: true)
          + "))"
      }

    public static func expansion<Ctx, Dcl>(of node: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol
      {
        guard let info = dcl.storedPropertyInfo else {
          throw Exception("@Attribute is only applicable to stored properties")
        }

        return [
          """
          get {
            let storedValue = self.value(forKey: "\(raw: info.name)")
            guard let value = storedValue as? \(raw: info.type) else { fatalError("\(raw: info.name) is not of expected type ...") }
            return value
          }
          """,
          """
          set {
            setValue(newValue, forKey: "\(raw: info.name)")
          }
          """,
        ]
      }

  }
