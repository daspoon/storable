/*

  Created by David Spooner

*/

import SwiftSyntax


struct StoredPropertyInfo
  {
    var name : String
    var type : TypeSyntax
    var value : ExprSyntax?
    var attributes : AttributeListSyntax?

    init?(_ decl: DeclSyntaxProtocol)
      {
        // Adapted from VariableDeclSyntax.isStoredProperty

        guard
          let variable = decl.as(VariableDeclSyntax.self),
          let binding = variable.bindings.first, variable.bindings.count == 1,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmed
        else {
          return nil
        }

        switch binding.accessor {
          case .none :
            break
          case .accessors(let node) :
            for accessor in node.accessors {
              switch accessor.accessorKind.tokenKind {
                case .keyword(.willSet), .keyword(.didSet) :
                  break
                default :
                  return nil
              }
            }
          case .getter :
            return nil
          @unknown default:
            return nil
        }

        self.name = name
        self.type = type
        self.value = binding.initializer?.value
        self.attributes = variable.attributes
      }
  }


