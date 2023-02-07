/*


*/

import XCTest
import Compendium
import CoreData


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

fileprivate let schema_v2 = try! Schema(name: "Model", objectTypes: [Person_v2.self])

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
          let store = try DataStore(schema: schema_v2, priorVersions: [schema_v1])

          // Retrieve the expected objects...
          _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Bill"))
          _ = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", "Ted"))
        }()
      }
  }


// MARK: --
// Define a third schema which adds a Place entity with a to-many/to-optional relationship to Person.

fileprivate let schema_v3 = try! Schema(name: "Model", objectTypes: [Person_v3.self, Place_v3.self])

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
          let store = try DataStore(schema: schema_v3, priorVersions: [schema_v1], reset: false)

          // Retrieve the expected objects...
          let bill = try store.fetchObject(of: Person_v3.self, satisfying: .init(format: "name = %@", "Bill"))
          _ = try store.fetchObject(of: Person_v3.self, satisfying: .init(format: "name = %@", "Ted"))

          // Add a place
          let there = try store.create(Place_v3.self) { $0.name = "Here"; $0.occupants = [bill] }
          XCTAssertEqual(bill.place, there)
        }()
      }
  }


// MARK: --
// Test change of attribute storage type

@objc fileprivate class Attributed_v1 : Object
  {
    @Attribute("a")
    var a : Int
  }

@objc fileprivate class Attributed_v2 : Object
  {
    @Attribute("a")
    var a : String
  }


extension MigrationTests
  {
    func testValueTypeChange() throws
      {
        // Create a schema with the original entity definition.
        let schema_v1 = try Schema(name: "test", objectTypes: [Attributed_v1.self])

        // Create the store for schema_v1 with some instances of the original entity
        let objectCount = 3
        try {
          let store = try DataStore(schema: schema_v1, reset: true)
          for i in 0 ..< objectCount {
            _ = try store.create(Attributed_v1.self) { $0.a = i }
          }
          try store.save()
        }()

        // Create another schema with the modified entity definition and a migration script...
        let schema_v2 = try Schema(name: "test", objectTypes: [Attributed_v2.self], migrationScript: { context in
          for object in try context.fetch(makeFetchRequest(for: Attributed_v1.self)) {
            guard let i = object.value(forKey: Schema.renameOld("a")) as? Int else { XCTFail("expecting integer value"); break }
            object.setValue("\(i)", forKey: Schema.renameNew("a"))
          }
        })

        // Re-open the store for schema_v2, performing the custom migration...
        try {
          let store = try DataStore(schema: schema_v2, priorVersions: [schema_v1])
          let objects = try store.managedObjectContext.fetch(makeFetchRequest(for: Attributed_v2.self))
          for object in objects {
            XCTAssertNotNil(object.value(forKey: "a") as? String, "expecting string value")
          }
        }()
      }
  }
