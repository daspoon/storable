/*

*/

import XCTest
import Compendium


final class DiffableTests : XCTestCase
  {
    func testDictionary() throws
      {
        XCTAssertEqual([String:Int]().difference(from: [:]), .init())

        XCTAssertEqual(["a": 1].difference(from: [:]), .init(added: ["a": 1]))
        XCTAssertEqual(["a": 1].difference(from: ["a": 2]), .init(modified: ["a": -1]))
        XCTAssertEqual([:].difference(from: ["a": 1]), .init(removed: ["a": 1]))

        XCTAssertEqual(["a": 1, "b": 5, "d": 4].difference(from: ["a": 1, "b": 2, "c": 3]), .init(
          added: ["d": 4],
          removed: ["c": 3],
          modified: ["b": 3]
        ))
      }

  }
