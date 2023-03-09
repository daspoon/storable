/*

  Created by David Spooner

  Demonstrate the function of supported relationship kinds...

    - to-one with to-many
    - to-one with optional to-one

*/

import XCTest
@testable import Storable


// MARK: --

fileprivate class Category : Entity
  {
    @Attribute("name")
    var name : String

    @Relationship("items", inverse: "category", deleteRule: .cascade)
    var items : Set<Item>
  }

fileprivate class Item : Entity
  {
    @Attribute("name")
    var name : String

    @Relationship("category", inverse: "items", deleteRule: .nullify)
    var category : Category

    @Relationship("box", inverse: "items", deleteRule: .nullify)
    var box : Box?
  }

fileprivate class Box : Entity
  {
    @Attribute("number")
    var number : Int

    @Relationship("items", inverse: "box", deleteRule: .nullify)
    var items : Set<Item>
  }


// MARK: --

final class RelationshipTests : XCTestCase
  {
    func test() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Box.self, Category.self, Item.self]))

        let pencils = try store.create(Category.self) { $0.name = "pencils" }
        let staplers = try store.create(Category.self) { $0.name = "stapers" }
        let good = try store.create(Box.self) { $0.number = 1 }
        let bad = try store.create(Box.self) { $0.number = 2 }
        let sharp = try store.create(Item.self) { $0.name = "sharp"; $0.category = pencils; $0.box = good }
        let dull = try store.create(Item.self) { $0.name = "dull"; $0.category = pencils; $0.box = bad }
        let empty = try store.create(Item.self) { $0.name = "empty"; $0.category = staplers; $0.box = bad }
        let full = try store.create(Item.self) { $0.name = "full"; $0.category = staplers; $0.box = good }
        let broken = try store.create(Item.self) { $0.name = "broken"; $0.category = staplers }

        try store.save()

        XCTAssertEqual(pencils.items, [sharp, dull])
        XCTAssertEqual(staplers.items, [full, empty, broken])
        XCTAssertEqual(good.items, [sharp, full])
        XCTAssertEqual(bad.items, [dull, empty])
        XCTAssertEqual(broken.box, nil)
      }
  }
