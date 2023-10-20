/*

  Created by David Spooner

  Convenience methods added to various types within the SwiftSyntax module.

*/

import SwiftSyntax


extension AttributeListSyntax
  {
    /// Return the single attribute instance whose name matches one of the given names. Returns a error if multiple attributes have matching names.
    func attributesWithNames(_ names: Set<String>) -> [AttributeSyntax]
      {
        var interesting : [AttributeSyntax] = []
        for element in self {
          guard case .attribute(let attribute) = element else { continue }
          guard names.contains(attribute.trimmedName) else { continue }
          interesting.append(attribute)
        }
        return interesting
      }
  }


extension AttributeSyntax
  {
    /// Return the attribute name with extraneous whitespace removed.
    var trimmedName : String
      { attributeName.trimmed.description }

    /// Return the associated argument list, if any.
    var argumentList : LabeledExprListSyntax?
      {
        guard case .argumentList(let list) = arguments else { return nil }
        return list
      }
  }


extension TypeSyntaxProtocol
  {
    /// Return the type name with verbose spelling if necessary to ensure "\(longName).self" can be parsed as a type instance.
    var longName : String
      {
        switch self.as(OptionalTypeSyntax.self) {
          case .some(let optional) :
            return "Optional<\(optional.wrappedType.description)>"
          case .none :
            return self.description
        }
      }


    /// Determine if the receiver is structually compatible with the given type. Note that not all type structures are considered and the relation is not symmetric.
    func isCompatible(with that: TypeSyntax) -> Bool
      {
        // All types are compatible with Any
        if let thatIdentifier = that.as(IdentifierTypeSyntax.self), thatIdentifier.name.description == "Any", thatIdentifier.genericArgumentClause == nil {
          return true
        }

        // Array types are compatible if their element types are compatible
        if let thisArray = self.as(ArrayTypeSyntax.self), let thatArray = that.as(ArrayTypeSyntax.self) {
          return thisArray.element.isCompatible(with: thatArray.element)
        }

        // Dictionary types are compatible if their key and value types are compatible
        if let thisDictionary = self.as(DictionaryTypeSyntax.self), let thatDictionary = that.as(DictionaryTypeSyntax.self) {
          return thisDictionary.key.isCompatible(with: thatDictionary.key)
            && thisDictionary.value.isCompatible(with: thatDictionary.value)
        }

        // Optional types are compatible if their wrapped types are compatible
        if let thisOptional = self.as(OptionalTypeSyntax.self), let thatOptional = that.as(OptionalTypeSyntax.self) {
          return thisOptional.wrappedType.isCompatible(with: thatOptional.wrappedType)
        }

        // Identifier types are compatible if they have the same spelling...
        if let thisIdentifier = self.as(IdentifierTypeSyntax.self), let thatIdentifier = that.as(IdentifierTypeSyntax.self) {
          guard thisIdentifier.name.description == thatIdentifier.name.description else { return false }
          switch (thisIdentifier.genericArgumentClause, thatIdentifier.genericArgumentClause) {
            case (.some(let thisClause), .some(let thatClause)) :
              return thisClause.arguments.count == thatClause.arguments.count
                && zip(thisClause.arguments, thatClause.arguments).allSatisfy { $0.argument.isCompatible(with: $1.argument) }
            case (.none, .none) :
              return true
            default :
              return false
          }
        }

        return false
      }

    /// Return the receiver's elementType if it is an array type, otherwise nil.
    var arrayElementType : TypeSyntax?
      {
        guard let arrayType = self.as(ArrayTypeSyntax.self) else { return nil }
        return arrayType.element
      }
  }


extension VariableDeclSyntax
  {
    /// Return the components of a stored property declaration, if applicable.
    var storedPropertyInfo : StoredPropertyInfo?
      {
        // Ensure the given declaration corresponds to a single variable with a name and a type...
        guard
          let binding = bindings.first, bindings.count == 1,
          let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
          let type = binding.typeAnnotation?.type.trimmed
        else {
          return nil
        }

        // Ensure the declaration's binding corresponds to a stored property
        switch binding.accessorBlock?.accessors {
          case .none :
            break
          case .accessors(let accessors) :
            for accessor in accessors {
              switch accessor.accessorSpecifier.tokenKind {
                case .keyword(.willSet), .keyword(.didSet) :
                  break
                default :
                  return nil
              }
            }
          case .getter :
            return nil
        }

        return (name, type, binding.initializer?.value)
      }
  }
