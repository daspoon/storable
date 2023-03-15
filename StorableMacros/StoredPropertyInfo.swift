/*

  Created by David Spooner

*/

import SwiftSyntax


struct StoredPropertyInfo
  {
    var name : String
    var type : TypeSyntax
    var value : ExprSyntax?
    var attribute : AttributeSyntax


    init?(_ decl: DeclSyntaxProtocol)
      {
        // Adapted from VariableDeclSyntax.isStoredProperty

        // Ensure the given declaration corresponds to a single variable with a name and a type...
        guard
          let variable = decl.as(VariableDeclSyntax.self),
          let binding = variable.bindings.first, variable.bindings.count == 1,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmed
        else {
          return nil
        }

        // Ensure the declaration's binding corresponds to a stored property
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

        // Ensure the declaration has a single attribute among Attribute, Relationship and Fetched...
        var supportedAttributes : [AttributeSyntax] = []
        if let attributes = variable.attributes {
          for element in attributes {
            guard case .attribute(let attribute) = element else { continue }
            guard Self.isSupportedAttribute(attribute) else { continue }
            supportedAttributes.append(attribute)
          }
        }
        switch supportedAttributes.count {
          case 0 :
            return nil
          case 1 :
            break
          default :
            // TODO: emit diagnostic indicating invalidity of multiple attributes...
            return nil
        }

        // The declaration has the required format; finish initialization
        self.name = name
        self.type = type
        self.value = binding.initializer?.value
        self.attribute = supportedAttributes[0]
      }


    static func isSupportedAttribute(_ attribute: AttributeSyntax) -> Bool
      {
        switch attribute.attributeName.trimmed.description {
          case "Attribute", "Relationship" :
            return true
          default :
            return false
        }
      }
  }
