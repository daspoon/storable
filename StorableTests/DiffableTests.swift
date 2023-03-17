/*

  Created by David Spooner

  Test dictionary difference calculation.

*/

import XCTest
import Storable


final class DiffableTests : XCTestCase
  {
    func testDictionary() throws
      {
        if try [String:Int]().difference(from: [:]) != .init() { XCTFail("") }

        if try ["a": 1].difference(from: [:]) != .init(added: ["a"]) { XCTFail("") }
        if try ["a": 1].difference(from: ["a": 2]) != .init(modified: ["a": -1]) { XCTFail("") }
        if try [:].difference(from: ["a": 1]) != .init(removed: ["a"]) { XCTFail("") }
        
        if try ["a": 1, "b": 5, "d": 4].difference(from: ["a": 1, "b": 2, "c": 3]) != .init(
          added: ["d"],
          removed: ["c"],
          modified: ["b": 3]
        ) { XCTFail("") }
      }


    struct Item : Diffable, Equatable
      {
        let value : Int
        let oldName : String?
        init(value v: Int, oldName x: String? = nil)
          { value = v; oldName = x }
        func difference(from old: Item) -> Int?
          { let delta = value - old.value; return delta != 0 ? delta : nil }
      }


    func testDictionaryRenaming() throws
      {
        let d1 = ["b": Item(value: 2)]
        let d2 = ["B": Item(value: 4, oldName: "b")]

        let diff : Dictionary<String, Item>.Difference? = try d2.difference(from: d1, moduloRenaming: \.oldName)

        if diff != .init(modified: ["B": 2]) { XCTFail("") }
      }
  }
