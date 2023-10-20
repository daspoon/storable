/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros
import Foundation


/// ManagedPropertyMacro defines the common features of macro types used to declare managed properties.
protocol ManagedPropertyMacro : AccessorMacro
  {
    /// Return the (string representation of the) initial sequence of arguments to the property metadata constructor which are inferred from the stored property declartion.
    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> String?
  }


extension ManagedPropertyMacro
  {
    /// Ensure the given declaration corresponds to a stored property compatible with macro application and return the relevant associated information.
    static func getStoredPropertyInfo(from decl: DeclSyntaxProtocol) throws -> StoredPropertyInfo
      {
        guard let vdecl = decl.as(VariableDeclSyntax.self), let info = vdecl.storedPropertyInfo else {
          throw Exception("@\(attributeName) is only applicable to stored properties")
        }
        guard case false = vdecl.modifiers.contains(where: {$0.name.trimmed.description == "override"}) else {
          throw Exception("@\(attributeName) is incompatible with override")
        }
        return info
      }

    /// Create an expression representing a new instance of the corresponding property metadata type from the details of the associated stored property and the arguments to the macro application.
    static func metadataConstructorExpr(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> ExprSyntax
      {
        let args : String
        switch (inferredMetadataConstructorArguments(for: info, with: attr), attr.argumentList) {
          case (.some(let inferredArgs), .some(let explicitArgs)) : args = inferredArgs + ", " + explicitArgs.description
          case (.some(let inferredArgs), .none) : args = inferredArgs
          case (.none, .some(let explicitArgs)) : args = explicitArgs.description
          case (.none, .none) : args = ""
        }
        return ".\(raw: Self.metadataTagName)(\(raw: Self.attributeName)(\(raw: args)))"
      }

    /// Return the name of the corresponding macro attribute as the type name minus the "Macro" suffix.
    static var attributeName : String
      {
        let typeName = "\(Self.self)"
        guard let range = typeName.range(of: "Macro", options: [.anchored, .backwards]) else { return typeName }
        return String(typeName[typeName.startIndex ..< range.lowerBound])
      }

    /// Return the case name for the enum which unifies the distinct property metadata types.
    static var metadataTagName : String
      { attributeName.lowercased() }
  }
