/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// RelationshipMacro enables defining NSRelationshipDescriptions from compatible variables of a managed object class.
public struct RelationshipMacro : ManagedPropertyMacro
  {
    // ManagedPropertyMacro

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> String?
      { "name: \"\(info.name)\", type: \(info.type.longName).self" }


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
