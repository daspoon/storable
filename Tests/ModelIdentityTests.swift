/*

*/

import XCTest
@testable import Compendium


final class ModelIdentityTests : XCTestCase
  { }


// Define some base entities. Although the subsequently defined variations have different class names, they have matching entity names due to their versioned class names (_v<i>).

@objc fileprivate class Person : Object
  {
    @Attribute("name")
    var name : String
  }

@objc fileprivate class Place : Object
  {
    @Attribute("name")
    var name : String
  }


// MARK: --
// Addition/removal of entities affects model identity.

@objc fileprivate class Extra : Object
  { }

extension ModelIdentityTests
  {
    func testEntityAddition() throws
      {
        let original = try Schema(name: "", objectTypes: [Person.self, Place.self])
        let modified = try Schema(name: "", objectTypes: [Person.self, Place.self, Extra.self])
        XCTAssertNotEqual(original.managedObjectModel.entityVersionHashesByName, modified.managedObjectModel.entityVersionHashesByName)
      }
  }


// MARK: --
// Addition/removal of attributes affects model identity.

@objc fileprivate class PersonWithAge : Object
  {
    @Attribute("name")
    var name : String
    @Attribute("birthdate")
    var birthdate : Date = .now
  }

extension ModelIdentityTests
  {
    func testAttributeAddition() throws
      {
        let original = try Schema(name: "", objectTypes: [Person.self, Place.self])
        let modified = try Schema(name: "", objectTypes: [PersonWithAge.self, Place.self])
        XCTAssertNotEqual(original.managedObjectModel.entityVersionHashesByName, modified.managedObjectModel.entityVersionHashesByName)
      }
  }


// MARK: --
// Addition/removal of relationships affects model identity.

fileprivate typealias PersonWithPlace = Person_v2
@objc fileprivate class Person_v2 : Object
  {
    @Attribute("name")
    var name : String
    @Relationship("place", inverseName: "occupants", deleteRule: .nullifyDeleteRule)
    var place : PlaceWithOccupants?
  }

fileprivate typealias PlaceWithOccupants = Place_v2
@objc fileprivate class Place_v2 : Object
  {
    @Attribute("name")
    var name : String
    @Relationship("occupants", inverseName: "place", deleteRule: .nullifyDeleteRule)
    var occupants : Set<PersonWithPlace>
  }

extension ModelIdentityTests
  {
    func testRelationshipAddition() throws
      {
        let original = try Schema(name: "", objectTypes: [Person.self, Place.self])
        let modified = try Schema(name: "", objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        XCTAssertNotEqual(original.managedObjectModel.entityVersionHashesByName, modified.managedObjectModel.entityVersionHashesByName)
      }
  }


// MARK: --
// Addition/removal of fetched properties does not affect model identity.

fileprivate typealias PlaceWithSortedOccupants = Place_v3
@objc fileprivate class Place_v3 : Object
  {
    @Attribute("name")
    var name : String
    @Relationship("occupants", inverseName: "place", deleteRule: .nullifyDeleteRule)
    var occupants : Set<Person>
    @FetchedProperty("occupantsByName", fetchRequest: makeFetchRequest(for: PersonWithPlace.self, sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantsByName : [PersonWithPlace]
  }

extension ModelIdentityTests
  {
    func testFetchAddition() throws
      {
        let original = try Schema(name: "", objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        let modified = try Schema(name: "", objectTypes: [PersonWithPlace.self, PlaceWithSortedOccupants.self])
        XCTAssertEqual(original.managedObjectModel.entityVersionHashesByName, modified.managedObjectModel.entityVersionHashesByName)
      }
  }


// MARK: --
// Changing the type of an attribute affects model identity.


// MARK: --
// Changing optionality of an attribute affects model identity.


// MARK: --
// Changing the type of a relationship affects model identity.
