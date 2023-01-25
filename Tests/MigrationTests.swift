/*


*/

import XCTest
import Compendium


// Define a class for migration tests added via extensions
final class MigrationTests : XCTestCase
  { }


// MARK: --
// Define an initial schema

fileprivate let schema_v1 = try! Schema(name: "Model", objectTypes: [Person_v1.self])

@objc
fileprivate class Person_v1 : Object
  {
    @Attribute("name")
    var name : String
  }


// MARK: --
// Define a second schema which adds an attribute to Person.

fileprivate let schema_v2 = try! Schema(name: "Model", version: 2, objectTypes: [Person_v2.self])

@objc
fileprivate class Person_v2 : Object
  {
    @Attribute("name")
    var name : String
    @Attribute("date")
    var date : Date = .now
  }

extension MigrationTests
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

        try {
          // Re-open the store using v2.
          let store = try DataStore(schema: schema_v2, priorVersions: [schema_v1], reset: false)

          // Retrieve the expected objects...
          _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Bill"))
          _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Ted"))
        }()
      }
  }


// MARK: --
// Define a third schema which adds a Place entity with a to-many/to-optional relationship to Person.

fileprivate let schema_v3 = try! Schema(name: "Model", version: 3, objectTypes: [Person_v3.self, Place_v3.self])

@objc
fileprivate class Person_v3 : Object
  {
    @Attribute("name")
    var name : String
    @Attribute("date")
    var date : Date = .now
    @Relationship("place", inverseName: "occupants", deleteRule: .nullifyDeleteRule)
    var place : Place_v3?
  }

@objc
fileprivate class Place_v3 : Object
  {
    @Attribute("name")
    var name : String
    @Relationship("occupants", inverseName: "place", deleteRule: .nullifyDeleteRule)
    var occupants : Set<Person_v3>
  }

extension MigrationTests
  {
    func testLightweightSequence() throws
      {
        // Create, populate, and close a store for v1.
        try {
          let store = try DataStore(schema: schema_v1, reset: true)
          _ = try store.create(Person_v1.self) { $0.name = "Bill" }
          _ = try store.create(Person_v1.self) { $0.name = "Ted" }
          try store.save()
        }()

        try {
          // Re-open the store using v3.
          let store = try DataStore(schema: schema_v3, priorVersions: [schema_v1, schema_v2], reset: false)

          // Retrieve the expected objects...
          let bill = try store.fetchObject(of: Person_v3.self, satisfying: .init(format: "name = %@", "Bill"))
          _ = try store.fetchObject(of: Person_v3.self, satisfying: .init(format: "name = %@", "Ted"))

          // Add a place
          let there = try store.create(Place_v3.self) { $0.name = "Here"; $0.occupants = [bill] }
          XCTAssertEqual(bill.place, there)
        }()
      }
  }
