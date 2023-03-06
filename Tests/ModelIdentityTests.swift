/*

  Created by David Spooner

*/

import XCTest
import CoreData
@testable import Storable


final class ModelIdentityTests : XCTestCase
  {
    func checkObjectModelHashes(match expectedMatch: Bool, _ original: Schema, _ modified: Schema) throws
      {
        let versionId = "*"
        let originalModel = try original.createRuntimeInfo(withVersionId: versionId).managedObjectModel
        let modifiedModel = try modified.createRuntimeInfo(withVersionId: versionId).managedObjectModel

        let actualMatch = originalModel.entityVersionHashesByName == modifiedModel.entityVersionHashesByName
        if actualMatch != expectedMatch {
          XCTFail("model hash values are expected to " + (expectedMatch ? "match" : "differ"))
        }
      }
  }


// Define some base entities. Although the subsequently defined variations have different class names, they have matching entity names due to their versioned class names (_v<i>).

@objc fileprivate class Person : Entity
  {
    @Attribute("name")
    var name : String
  }

@objc fileprivate class Place : Entity
  {
    @Attribute("name")
    var name : String
  }


// MARK: --
// Addition/removal of entities affects model identity.

@objc fileprivate class Extra : Entity
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

@objc fileprivate class PersonWithAge : Entity
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
@objc fileprivate class Person_v2 : Entity
  {
    @Attribute("name")
    var name : String
    @Relationship("place", inverseName: "occupants", deleteRule: .nullifyDeleteRule)
    var place : PlaceWithOccupants?
  }

fileprivate typealias PlaceWithOccupants = Place_v2
@objc fileprivate class Place_v2 : Entity
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
        let original = try Schema(objectTypes: [Person.self, Place.self])
        let modified = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        try checkObjectModelHashes(match: false, original, modified);
      }
  }


// MARK: --
// Addition/removal of fetched properties does not affect model identity.

fileprivate typealias PlaceWithSortedOccupants = Place_v3
@objc fileprivate class Place_v3 : Entity
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
        let original = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithOccupants.self])
        let modified = try Schema(objectTypes: [PersonWithPlace.self, PlaceWithSortedOccupants.self])
        try checkObjectModelHashes(match: true, original, modified);
      }
  }
