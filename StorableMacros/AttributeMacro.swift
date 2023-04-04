/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// AttributeMacro enables defining NSAttributeDescriptions from compatible variables of a managed object class.
public struct AttributeMacro : ManagedPropertyMacro
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
          "get { attributeValue(forKey: \"\(raw: info.name)\") }",
          "set { setAttributeValue(newValue, forKey: \"\(raw: info.name)\") }",
        ]
      }
  }
