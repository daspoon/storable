/*

  Created by David Spooner

*/

import XCTest
import CoreData
@testable import Storable


final class ModelIdentityTests : XCTestCase
  {
  }


// Define some base entities. Although the subsequently defined variations have different class names, they have matching entity names due to their versioned class names (_v<i>).

fileprivate class Person : Entity
  {
    @Attribute("name")
    var name : String
  }

fileprivate class Place : Entity
  {
    @Attribute("name")
    var name : String
  }


// MARK: --
// Addition/removal of entities affects model identity.

fileprivate class Extra : Entity
  { }

extension ModelIdentityTests
  {
    func testEntityAddition() throws
      {
        let original = try Schema(objectTypes: [Person.self, Place.self])
        let modified = try Schema(objectTypes: [Person.self, Place.self, Extra.self])
        try checkObjectModelHashes(match: false, original, modified);
      }
  }


// MARK: --
// Addition/removal of attributes affects model identity.

fileprivate class PersonWithAge : Entity
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
        let original = try Schema(objectTypes: [Person.self, Place.self])
        let modified = try Schema(objectTypes: [PersonWithAge.self, Place.self])
        try checkObjectModelHashes(match: false, original, modified);
      }
  }


// MARK: --
// Addition/removal of relationships affects model identity.

fileprivate typealias PersonWithPlace = Person_v2
fileprivate class Person_v2 : Entity
  {
    @Attribute("name")
    var name : String
    @Relationship("place", inverseName: "occupants", deleteRule: .nullify)
    var place : PlaceWithOccupants?
  }

fileprivate typealias PlaceWithOccupants = Place_v2
fileprivate class Place_v2 : Entity
  {
    @Attribute("name")
    var name : String
    @Relationship("occupants", inverseName: "place", deleteRule: .nullify)
    var occupants : Set<PersonWithPlace>
  }

extension ModelIdentityTests
  {
    func testRelationshipAddition() throws
      {
        let original = try Schema(objectTypes: [Person.self, Place.self])
        let modified = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        try checkObjectModelHashes(match: false, original, modified);
      }
  }


// MARK: --
// Addition/removal of fetched properties does not affect model identity.

fileprivate typealias PlaceWithSortedOccupants = Place_v3
fileprivate class Place_v3 : Entity
  {
    @Attribute("name")
    var name : String
    @Relationship("occupants", inverseName: "place", deleteRule: .nullify)
    var occupants : Set<Person>
    @FetchedProperty("occupantsByName", fetchRequest: makeFetchRequest(for: PersonWithPlace.self, sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantsByName : [PersonWithPlace]
  }

extension ModelIdentityTests
  {
    func testFetchAddition() throws
      {
        let original = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        let modified = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithSortedOccupants.self])
        try checkObjectModelHashes(match: true, original, modified);
      }
  }
