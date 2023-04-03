/*

  Created by David Spooner

  Demonstrate the function of supported relationship kinds...

*/

#if swift(>=5.9)

import XCTest
import Storable


final class RelationshipTests : XCTestCase
  {
    func test() throws
      {
        @ManagedObject class Category : ManagedObject {
          @Attribute var name : String
          @Relationship(inverse: "category", deleteRule: .cascade) var items : Set<Item>
        }

        @ManagedObject class Item : ManagedObject {
          @Attribute var name : String
          @Relationship(inverse: "items", deleteRule: .nullify) var category : Category
          @Relationship(inverse: "items", deleteRule: .nullify) var box : Box?
        }

        @ManagedObject class Box : ManagedObject {
          @Attribute var number : Int
          @Relationship(inverse: "box", deleteRule: .nullify) var items : Set<Item>
        }

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

        if pencils.items != [sharp, dull] { XCTFail("") }
        if staplers.items != [full, empty, broken] { XCTFail("") }
        if good.items != [sharp, full] { XCTFail("") }
        if bad.items != [dull, empty] { XCTFail("") }
        if broken.box != nil { XCTFail("") }
      }
  }

#endif
