/*


*/

import XCTest
import Compendium
import CoreData


final class MigrationTests : XCTestCase
  { }


// MARK: - Test lightweight migration -

extension MigrationTests
  {
    func testLightweight() throws
      {
        // Define an initial schema with a single Person entity
        @objc class Person_v1 : Object {
          @Attribute("name")
          var name : String
          @Attribute("date")
          var date : Date = .now
        }
        let schema_v1 = try! Schema(objectTypes: [Person_v1.self])

        // Define an evolved schema which removes an attribute and adds an optional-to-many relationship to a new entity Place.
        @objc class Person_v2 : Object {
          @Attribute("name")
          var name : String
          @Attribute("date")
          var date : Date = .now
          @Relationship("place", inverseName: "occupants", deleteRule: .nullifyDeleteRule)
          var place : Place_v2?
        }
        @objc class Place_v2 : Object {
          @Attribute("name")
          var name : String
          @Relationship("occupants", inverseName: "place", deleteRule: .nullifyDeleteRule)
          var occupants : Set<Person_v2>
        }
        let schema_v2 = try! Schema(objectTypes: [Person_v2.self, Place_v2.self])

        // Create, populate, save and close a store for v1.
        let store = try createAndOpenStoreWith(schema: schema_v1)
        let personNames = ["Bill", "Ted"]
        for name in personNames {
          _ = try store.create(Person_v1.self) { $0.name = name }
        }
        try store.close()

        // Re-open the store using v2, create a Place and assign it to the existing Person objects.
        try store.openWith(schema: schema_v2, migrations: [
          .init(from: schema_v1),
        ])
        let here = try store.create(Place_v2.self) { $0.name = "Here" }
        for name in personNames {
          let person = try store.fetchObject(of: Person_v2.self, satisfying: .init(format: "name = %@", name))
          person.place = here
        }
        XCTAssertEqual(here.occupants.count, personNames.count)
      }
  }


// MARK: - Test change of attribute storage type -

extension MigrationTests
  {
    func testAttributeStorageType() throws
      {
        // Define two entities with an attribute of the same name but different storage types.
        @objc class Attributed_v1 : Object {
          @Attribute("a")
          var a : Int
        }
        @objc class Attributed_v2 : Object {
          @Attribute("a")
          var a : String
        }

        // Create a schema with the original entity definition.
        let schema_v1 = try Schema(objectTypes: [Attributed_v1.self])

        // Create the store for schema_v1 with some instances of the original entity
        let objectCount = 3
        let store = try createAndOpenStoreWith(schema: schema_v1)
        for i in 0 ..< objectCount {
          _ = try store.create(Attributed_v1.self) { $0.a = i }
        }
        try store.close()

        // Create another schema with the modified entity definition and a migration script...
        let schema_v2 = try Schema(objectTypes: [Attributed_v2.self])

        // Re-open the store for schema_v2, performing the custom migration...
        try store.openWith(schema: schema_v2, migrations: [
          .init(from: schema_v1) { context in
            for object in try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Attributed")) {
              guard let i = object.value(forKey: Schema.renameOld("a")) as? Int else { XCTFail("expecting integer value"); break }
              object.setValue("\(i)", forKey: Schema.renameNew("a"))
            }
          },
        ])
        let objects = try store.managedObjectContext.fetch(makeFetchRequest(for: Attributed_v2.self))
        for object in objects {
          XCTAssertNotNil(object.value(forKey: "a") as? String, "expecting string value")
        }
      }
  }


// MARK: - Test change of attribute value type -

extension MigrationTests
  {
    func testAttributeValueType() throws
      {
        // Define non-standard some attribute types
        struct Point2d : StorableAsData { var x, y : Int }
        struct Point3d : StorableAsData { var x, y, z : Int }

        // Define an initial entity with an attribute of type Point2d
        @objc class Thing_v2 : Object {
          @Attribute("point") var point : Point2d
        }
        let schema_v2 = try Schema(objectTypes: [Thing_v2.self])

        // Define an evolved entity where the point attribute has changed type, but retains the storage type 'binaryData'
        @objc class Thing_v3 : Object {
          @Attribute("point") var point : Point3d
        }
        let schema_v3 = try Schema(objectTypes: [Thing_v3.self])

        // Create, populate and close a store for the 2d schema.
        let store = try createAndOpenStoreWith(schema: schema_v2)
        let objectCount = 3
        for i in 0 ..< objectCount {
          _ = try store.create(Thing_v2.self) { $0.point = Point2d(x: i, y: i) }
        }
        try store.close()

        // Re-open the store for the 3d schema, performing the custom migration to convert attribute values from 2d to 3d :)
        try store.openWith(schema: schema_v3, migrations: [
          .init(from: schema_v2) { context in
            // Note that the store now contains attributes of both the old and new types with distinct names...
            for thing in try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing")) {
              let p = try thing.unboxedValue(of: Point2d.self, forKey: Schema.renameOld("point"))
              thing.setBoxedValue(Point3d(x: p.x, y: p.y, z: 0), forKey: Schema.renameNew("point"))
            }
          },
        ])
        let things = try store.managedObjectContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing"))
        XCTAssertEqual(things.count, objectCount)
        for thing in things {
          _ = try thing.unboxedValue(of: Point3d.self, forKey: "point")
        }
      }
  }


// MARK: - Test change of attribute optionality -

extension MigrationTests
  {
    func testAtributeOptionality() throws
      {
      // TODO: this test fails because changing optionality currently implies changing type, so...
      //   - a script is unnecessarily demanded for the migration from v1 to v2
      //   - the script migrating from v2 to v1 fails because the attribute has been unnecessarily renamed

        let objectCount = 3

        // Define entity e1 with a non-optional attribute a
        let schema_v1 = try Schema(objectTypes: [Entity_v1.self])
        @objc class Entity_v1 : Object {
          @Attribute("a") var a : Int
        }

        // Define same-named entity e2 with an optional attribute a of the same type
        let schema_v2 = try Schema(objectTypes: [Entity_v2.self])
        @objc class Entity_v2 : Object {
          @OptionalAttribute("a") var a : Int?
        }

        // Create and populate a store using the schema in which the attribute is non-optional.
        let store = try createAndOpenStoreWith(schema: schema_v1)
        for i in 0 ..< objectCount {
          _ = try store.create(Entity_v1.self) { $0.a = i }
        }
        try store.close()

        // Re-open the store with the alternate schema, with implicit lightweight migration
        try store.openWith(schema: schema_v2, migrations: [.init(from: schema_v1)])
        try store.close()

        // Re-create and populate store using the schema in which the attribute is optional.
        try store.reset()
        try store.openWith(schema: schema_v2)
        for _ in 0 ..< objectCount {
          _ = try store.create(Entity_v2.self)
        }
        try store.close()

        // Attempting to re-open the store with the alternate schema must now fail without a migration script.
        do {
          try store.openWith(schema: schema_v1, migrations: [.init(from: schema_v2)])
          XCTFail("expecting failure to open store")
        }
        catch let error {
          print(error)
        }

        // Re-open the store with the alternate schema and a migration script to ensure each attribute has a non-nil value.
        try store.openWith(schema: schema_v1, migrations: [
          .init(from: schema_v2) { context in
            for object in try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Entity")) {
              guard object.value(forKey: "a") == nil else { continue }
              object.setValue(-1, forKey: "a")
            }
          },
        ])
      }
  }


// MARK: - Test change of relationship arity -

extension MigrationTests
  {
    func testRelationshipArity() throws
      {
        // Define an initial schema with Thing and Place entities related by to-optional relationships 'place' and 'thing'.
        @objc class Thing : Object {
          @Relationship("place", inverseName: "thing", deleteRule: .nullifyDeleteRule)
          var place : Place?
        }
        @objc class Place : Object {
          @Relationship("thing", inverseName: "place", deleteRule: .nullifyDeleteRule)
          var thing : Thing?
        }

        // Define an evolved schema where 'place' becomes to-one, and 'thing' becomes to-many and is renamed 'things'.
        @objc class Thing_v2 : Object {
          @Relationship("place", inverseName: "things", deleteRule: .nullifyDeleteRule)
          var place : Place_v2
        }
        @objc class Place_v2 : Object {
          @Relationship("things", inverseName: "place", deleteRule: .cascadeDeleteRule, renamingIdentifier: "thing")
          var things : Set<Thing_v2>
        }

        // The migration from v1 to v2 must ensure each Thing has a Place...
        let schema_v1 = try Schema(objectTypes: [Thing.self, Place.self])
        let schema_v2 = try Schema(objectTypes: [Thing_v2.self, Place_v2.self])

        // Create, populate and close a store for the initial schema.
        let store = try createAndOpenStoreWith(schema: schema_v1)
        let thingCount = 3
        let someplace = try store.create(Place.self)
        _ = try store.create(Thing.self) { $0.place = someplace }
        for _ in 1 ..< thingCount {
          _ = try store.create(Thing.self)
        }
        try store.close()

        // Re-open the store for the evolved schema, performing the specified migration.
        try store.openWith(schema: schema_v2, migrations: [
          .init(from: schema_v1) { context in
            let unplaced = try context.create(Place.self)
            for thing in try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing")) {
              guard thing.value(forKey: "place") == nil else { continue }
              thing.setValue(unplaced, forKey: "place")
            }
          },
        ])
        let places = try store.managedObjectContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Place"))
        XCTAssertEqual(places.count, 2)
        let things = try store.managedObjectContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "Thing"))
        XCTAssertEqual(things.count, thingCount)
      }
  }
