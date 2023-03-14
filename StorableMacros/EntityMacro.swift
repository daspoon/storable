/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct EntityMacro : MemberMacro
  {
    public static func expansion(
      of node: AttributeSyntax,
      providingMembersOf declaration: some DeclGroupSyntax,
      in context: some MacroExpansionContext
    ) throws -> [DeclSyntax]
      {
        guard
          let classDecl = declaration.as(ClassDeclSyntax.self)
          //let inheritedType : TypeSyntax = classDecl.inheritanceClause?.inheritedTypeCollection.first?.typeName
        else {
          return []
        }

        let storedPropertyInfoArray = classDecl.members.members.compactMap {StoredPropertyInfo($0.decl)}
        var text = "public override class var declaredPropertyInfoByName : [String: PropertyInfo] {"
        text.append("  return [")
        if storedPropertyInfoArray.count == 0 {
          text.append(":]\n")
        }
        else {
          text.append("\n")
          for info in storedPropertyInfoArray {
            text.append(
              """
                  \"\(info.name)\" : .attribute(.init(name: "\(info.name)", type: \(info.type).self, defaultValue: \(info.value ?? "nil"))),\n
              """
            )
          }
          text.append("  ]\n")
        }
        text.append("}\n")

        return [DeclSyntax(stringLiteral: text)]
      }
  }
