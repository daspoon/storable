/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// FetchedMacro enables defining NSFetchedPropertyDescriptions from compatible variables of a managed object class.
public struct FetchedMacro : ManagedPropertyMacro
  {
    enum Mode { case objects, count, identifiers, dictionaries }

    /// Determine the mode according to the label of the macro attribute's first argument, if any.
    private static func mode(for attribute: AttributeSyntax) -> Mode
      {
        switch attribute.argumentList?.first?.label?.description {
          case "countOf" : return .count
          case "identifiersOf" : return .identifiers
          case "dictionariesOf" : return .dictionaries
          default :
            return .objects
        }
      }

    // ManagedPropertyMacro

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attribute: AttributeSyntax) -> String?
      {
        switch mode(for: attribute) {
          case .objects :
            return "objectsOf: \(info.type.arrayElementType!).self"
          default :
            return nil
        }
      }

    // AccessorMacro

    public static func expansion<Ctx, Dcl>(of attribute: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol
      {
        let info = try getStoredPropertyInfo(from: dcl)

        let mode = Self.mode(for: attribute)
        switch mode {
          case .objects :
            guard info.type.isCompatible(with: TypeSyntax("[Any]")) else { throw Exception("@\(Self.self) is not applicable to type \(info.type)") }
          case .count :
            guard info.type.isCompatible(with: TypeSyntax("Int")) else { throw Exception("@\(Self.self)(countOf:) requires declaration type Int") }
          case .identifiers :
            guard info.type.isCompatible(with: TypeSyntax("[NSManagedObjectID]")) else { throw Exception("@\(Self.self)(identifiersOf:) requires declaration type [NSManagedObjectID]") }
          case .dictionaries :
            guard info.type.isCompatible(with: TypeSyntax("[[String: Any]]")) else { throw Exception("@\(Self.self)(dictionariesOf:) requires declaration type [[String: Any]]") }
        }

        let result : AccessorDeclSyntax
        switch mode {
          case .count : result =
            """
            get {
              guard let array = self.value(forKey: "\(raw: info.name)") as? [\(raw: info.type)], array.count == 1 else { fatalError("\(raw: info.name) is not of expected format ...") }
              return array[0]
            }
            """
          default :  result =
            """
            get {
              guard let value = self.value(forKey: "\(raw: info.name)") as? \(raw: info.type) else { fatalError("\(raw: info.name) is not of expected format ...") }
              return value
            }
            """
        }

        return [result]
      }
  }
