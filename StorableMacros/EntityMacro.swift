/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// EntityMacro enables defining an NSEntityDescription from a managed object class.
public struct EntityMacro : MemberMacro
  {
    /// The types of macros which correspond to managed property declarations.
    static let propertyMacroTypes : [ManagedPropertyMacro.Type]
      = [AttributeMacro.self, FetchedMacro.self, RelationshipMacro.self]

    static let propertyMacroNames : Set<String>
      = Set(propertyMacroTypes.map {$0.attributeName})

    static let propertyMacroTypesByName : [String: ManagedPropertyMacro.Type]
      = Dictionary(uniqueKeysWithValues: propertyMacroTypes.map {($0.attributeName, $0)})


    // MemberMacro

    public static func expansion(of node: AttributeSyntax, providingMembersOf dcl: some DeclGroupSyntax, in ctx: some MacroExpansionContext) throws -> [DeclSyntax]
      {
        guard let dcl = dcl.as(ClassDeclSyntax.self) else {
          throw Exception("@Entity is applicable only to class definitions")
        }

        var text = "public override class var declaredPropertiesByName : [String: Property] {\n"
        text.append("  return [")
        var count = 0
        for member in dcl.members.members {
          // Ignore member declarations which are not stored properties
          guard let vdecl = member.decl.as(VariableDeclSyntax.self), let info = vdecl.storedPropertyInfo else { continue }
          // Get the attributes which correspond to managed property declarations
          let macroAttrs = vdecl.attributes?.attributesWithNames(propertyMacroNames) ?? []
          // Ignore members declarations which have no attributes
          guard macroAttrs.count > 0 else { continue }
          // Complain if multiple property macros are specified
          guard macroAttrs.count == 1 else { throw Exception("cannot intermix attributes among \(propertyMacroNames)") }
          // Generate a dictionary entry mapping the declared member name to a managed property descriptor
          let macroType = propertyMacroTypesByName[macroAttrs[0].trimmedName]!
          text.append("    \"\(info.name)\" : \(macroType.metadataConstructorExpr(for: info, with: macroAttrs[0])),\n")
          count += 1
        }
        text.append((count == 0 ? ":]" : "  ]") + "\n")
        text.append("}\n")

        return [DeclSyntax(stringLiteral: text)]
      }
  }
