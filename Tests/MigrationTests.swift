/*

  A lightweight migration which adds an attribute with a default value.

*/

import XCTest
import Compendium


@objc
fileprivate class Person_v1 : Object
  {
    @Attribute("name")
    var name : String
  }

fileprivate let schema_v1 = try! Schema(name: "Model", objectTypes: [Person_v1.self])


@objc
fileprivate class Person_v2 : Object
  {
    @Attribute("name")
    var name : String
    @Attribute("date")
    var date : Date = .now
  }

fileprivate let schema_v2 = try! Schema(name: "Model", version: 2, objectTypes: [Person_v2.self])


final class MigrationTests : XCTestCase
  {
    func testLightweight() throws
      {
        // Create, populate, and close a store for v1.
        try {
          let store = try DataStore(schema: schema_v1, reset: true)
          _ = try store.create(Person_v1.self) { $0.name = "Bill" }
          _ = try store.create(Person_v1.self) { $0.name = "Ted" }
          try store.save()
        }()

        // Re-open the store using v2.
        let store = try DataStore(schema: schema_v2, priorVersions: [schema_v1], reset: false)

        // Retrieve the expected objects...
        _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Bill"))
        _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Ted"))
      }
  }
