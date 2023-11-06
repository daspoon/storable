/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct TransientMacro : ManagedPropertyMacro
  {
    // ManagedPropertyMacro

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> String?
      { "name: \"\(info.name)\", type: \(info.type.longName).self" + (info.value.map {", defaultValue: \($0)"} ?? "") }


    // AccessorMacro

    public static func expansion<Ctx, Dcl>(of node: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol
      {
        let info = try getStoredPropertyInfo(from: dcl)
        return [
          "get { transientValue(forKey: \"\(raw: info.name)\") }",
          "set { setTransientValue(newValue, forKey: \"\(raw: info.name)\") }",
        ]
      }
  }
