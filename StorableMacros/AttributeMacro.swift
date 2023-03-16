/*

  Created by David Spooner

*/

import SwiftSyntax
import SwiftSyntaxMacros


public struct AttributeMacro  : AccessorMacro
  {
    public static func expansion<Ctx: MacroExpansionContext, Decl: DeclSyntaxProtocol>(
      of node: AttributeSyntax,
      providingAccessorsOf decl: Decl,
      in ctx: Ctx
    ) throws -> [AccessorDeclSyntax]
      {
        // TODO: ensure enclosing type is an NSManagedObject
        // TODO: ensure declared type is Storable
        // TODO: use enclosing class name in error messages
        guard
          let info = StoredPropertyInfo(decl)
        else {
          return []
        }

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
