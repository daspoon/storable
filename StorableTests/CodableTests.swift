/*

  Created by David Spooner

  Test assumptions about synthesized Codable implementations.

*/

import Foundation
import XCTest


final class CodableTests : XCTestCase
  {
    /// A convenience function which returns the result of encoding and decoding the given value, optionally with different types.
    func copy<S: Codable, T: Codable>(_ source: S, as targetType: T.Type = T.self) throws -> T
      {
        let data = try JSONEncoder().encode(source)
        return try JSONDecoder().decode(targetType, from: data)
      }

    /// Struct names can change between encoding and decoding.
    func testTypeNameChange() throws
      {
        struct S1 : Codable { var name : String; var value : Int }
        struct S2 : Codable { var name : String; var value : Int }

        print(try copy(S1(name: "me", value: 1), as: S2.self))
      }

    /// Properties can be removed.
    func testPropertyRemoval() throws
      {
        struct S1 : Codable { var name : String; var value : Int; var removed : Bool }
        struct S2 : Codable { var name : String; var value : Int }

        print(try copy(S1(name: "me", value: 1, removed: true), as: S2.self))
      }

    /// Mutable properties cannot be added.
    func testPropertyAddition() throws
      {
        struct S1 : Codable { var name : String; var value : Int }
        struct S2 : Codable { var name : String; var value : Int; var added : Bool = true }
        do {
          _ = try copy(S1(name: "me", value: 1), as: S2.self)
          XCTFail("failed to throw")
        }
        catch {
          // ▿ DecodingError
          //   ▿ keyNotFound : 2 elements
          //     - .0 : CodingKeys(stringValue: "added", intValue: nil)
          //     ▿ .1 : Context
          //       - codingPath : 0 elements
          //       - debugDescription : "No value associated with key CodingKeys(stringValue: \"added\", intValue: nil) (\"added\")."
          //       - underlyingError : nil
        }
      }

    /// Addition and removal of enum cases is fine provided the encoded value remains intact.
    func testEnumCaseChange() throws
      {
        enum E1 : Codable { case one, two, three }
        enum E2 : Codable { case two, three, four }

        if try copy(E1.two, as: E2.self) != .two { XCTFail("") }

        do {
          _ = try copy(E1.one, as: E2.self)
          XCTFail("")
        }
        catch { }
      }
  }
