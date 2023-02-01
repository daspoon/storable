/*

*/

import XCTest
import Compendium


final class DiffableTests : XCTestCase
  {
    func testDictionary() throws
      {
        XCTAssertEqual(try [String:Int]().difference(from: [:]), .init())

        XCTAssertEqual(try ["a": 1].difference(from: [:]), .init(added: ["a": 1]))
        XCTAssertEqual(try ["a": 1].difference(from: ["a": 2]), .init(modified: ["a": -1]))
        XCTAssertEqual(try [:].difference(from: ["a": 1]), .init(removed: ["a": 1]))

        XCTAssertEqual(try ["a": 1, "b": 5, "d": 4].difference(from: ["a": 1, "b": 2, "c": 3]), .init(
          added: ["d": 4],
          removed: ["c": 3],
          modified: ["b": 3]
        ))
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

        XCTAssertEqual(diff, .init(modified: ["B": 2]))
      }
  }
