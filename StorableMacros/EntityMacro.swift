/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct EntityMacro : MemberMacro
  {
    /// The types of macros which correspond to managed property declarations.
    static let propertyMacroTypes : [ManagedPropertyMacro.Type] = [
      AttributeMacro.self,
      FetchedMacro.self,
      RelationshipMacro.self,
    ]

    static let propertyMacroNames : Set<String>
      = Set(propertyMacroTypes.map {$0.attributeName})

    static let propertyMacroTypesByName : [String: ManagedPropertyMacro.Type]
      = .init(uniqueKeysWithValues: propertyMacroTypes.map {($0.attributeName, $0)})


    // MemberMacro

    public static func expansion(of node: AttributeSyntax, providingMembersOf dcl: some DeclGroupSyntax, in ctx: some MacroExpansionContext) throws -> [DeclSyntax]
      {
        guard let dcl = dcl.as(ClassDeclSyntax.self) else {
          throw Exception("@Entity is applicable only to class definitions")
        }

        var text = "public override class var declaredPropertyInfoByName : [String: PropertyInfo] {\n"
        text.append("  return [")
        var count = 0
        for item in dcl.members.members {
          // Ignore member declarations which are not stored properties
          guard let info = item.decl.storedPropertyInfo else { continue }
          // Get the attributes which correspond to managed property declarations
          let attributes = try info.attributes?.attributesWithNames(propertyMacroNames) ?? []
          // Ignore members declarations which have no attributes and complain abount member declarations which have multiple attributes
          switch attributes.count {
            case 0 :
              continue
            case let n where n > 1 :
              throw Exception("cannot intermix attributes among \(propertyMacroNames)")
            default :
              break
          }
          // Generate a dictionary entry mapping the variable name to a managed property descriptor
          guard let macroType = propertyMacroTypesByName[attributes[0].trimmedName] else { throw Exception("*** failed to get generator type for '\(attributes[0].trimmedName)' ***") }
          text.append("    \"\(info.name)\" : \(try macroType.generateDescriptorText(for: info, using: attributes[0])),\n")
          count += 1
        }
        text.append((count == 0 ? ":]" : "  ]") + "\n")
        text.append("}\n")

        return [DeclSyntax(stringLiteral: text)]
      }
  }
