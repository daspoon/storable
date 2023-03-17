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

@Entity fileprivate class Person : Entity
  {
    @Attribute
    var name : String
  }

@Entity fileprivate class Place : Entity
  {
    @Attribute
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

@Entity fileprivate class PersonWithAge : Entity
  {
    @Attribute
    var name : String
    @Attribute
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
@Entity fileprivate class Person_v2 : Entity
  {
    @Attribute
    var name : String
    @Relationship(inverse: "occupants", deleteRule: .nullify)
    var place : PlaceWithOccupants?
  }

fileprivate typealias PlaceWithOccupants = Place_v2
@Entity fileprivate class Place_v2 : Entity
  {
    @Attribute
    var name : String
    @Relationship(inverse: "place", deleteRule: .nullify)
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
@Entity fileprivate class Place_v3 : Entity
  {
    @Attribute
    var name : String
    @Relationship(inverse: "place", deleteRule: .nullify)
    var occupants : Set<Person>
    @Fetched(sortDescriptors: [.init(key: "name", ascending: true)])
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
