/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct RelationshipMacro  : AccessorMacro
  {
    public static func expansion<Ctx: MacroExpansionContext, Decl: DeclSyntaxProtocol>(
      of node: AttributeSyntax,
      providingAccessorsOf decl: Decl,
      in ctx: Ctx
    ) throws -> [AccessorDeclSyntax]
      {
        // TODO: ensure enclosing type is an Entity
        // TODO: ensure declared type is an Entity
        // TODO: use enclosing class name in error messages

        guard
          let info = StoredPropertyInfo(decl)
        else {
          return []
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
