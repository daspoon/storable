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
          "get { value(forKey: \"\(raw: info.name)\") as! \(raw: info.type) }",
          "set { setValue(newValue, forKey: \"\(raw: info.name)\") }",
        ]
      }

  }
