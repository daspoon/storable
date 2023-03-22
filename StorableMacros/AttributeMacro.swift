/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


/// AttributeMacro enables defining NSAttributeDescriptions from compatible variables of a managed object class.
public struct AttributeMacro : ManagedPropertyMacro
  {
    // ManagedPropertyMacro

    static var attributeName : String { "Attribute" }

    static func generateDescriptorText(for decl: StoredPropertyInfo, using attribute: AttributeSyntax) throws -> String
      {
        return ".attribute(.init(name: \"\(decl.name)\", type: \(decl.type.longName).self"
          + (decl.value.map { ", defaultValue: \($0)" } ?? "")
          + generateDescriptorArgumentText(for: attribute.argument, withInitialComma: true)
          + "))"
      }

    // AccessorMacro

    public static func expansion<Ctx, Dcl>(of node: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol
      {
        let info = try getStoredPropertyInfo(from: dcl)

        switch info.type.as(OptionalTypeSyntax.self) {
          case .none :
            return [
              """
              get {
                switch self.value(forKey: "\(raw: info.name)") {
                  case .some(let objectValue) :
                    guard let encodedValue = objectValue as? \(raw: info.type).EncodingType else { fatalError("\(raw: info.name) is not of expected type ...") }
                    return \(raw: info.type).decodeStoredValue(encodedValue)
                  case .none :
                    fatalError("\(raw: info.name) is not initialized")
                }
              }
              """,
              """
              set {
                self.setValue(newValue.storedValue(), forKey: "\(raw: info.name)")
              }
              """,
            ]
          case .some(let optionalType) :
            return [
              """
              get {
                switch self.value(forKey: "\(raw: info.name)") {
                  case .some(let objectValue) :
                    guard let encodedValue = objectValue as? \(raw: optionalType.wrappedType).EncodingType else { fatalError("\(raw: info.name) is not of expected type ...") }
                    return \(raw: optionalType.longName).inject(\(raw: optionalType.wrappedType).decodeStoredValue(encodedValue))
                  case .none :
                    return nil
                }
              }
              """,
              """
              set {
                self.setValue(\(raw: optionalType.longName).project(newValue)?.storedValue(), forKey: "\(raw: info.name)")
              }
              """,
            ]
        }
      }
  }
