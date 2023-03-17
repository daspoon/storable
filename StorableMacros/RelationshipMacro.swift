/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// RelationshipMacro enables defining NSRelationshipDescriptions from compatible variables of a managed object class.
public struct RelationshipMacro : ManagedPropertyMacro, AccessorMacro
  {
    // ManagedPropertyMacro

    static var attributeName : String { "Relationship" }

    static func generateDescriptorText(for decl: StoredPropertyInfo, using attribute: AttributeSyntax) throws -> String
      {
        return ".relationship(.init(name: \"\(decl.name)\", type: \(decl.type.longName).self"
          + generateDescriptorArgumentText(for: attribute.argument, withInitialComma: true)
          + "))"
      }

    // AccessorMacro

    public static func expansion<Ctx, Dcl>(of node: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol
      {
        let info = try getStoredPropertyInfo(from: dcl)

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
