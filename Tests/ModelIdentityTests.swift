/*

*/

import XCTest
import CoreData
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
// Confirm expected effects on versionHash for NSPropertyDescription and NSEntityDescription...

// For convenience, define a protocol allowing common treatment of those classes;
protocol ObjectModelComponent : NSObject
  { var versionHash : Data { get } }

extension NSEntityDescription : ObjectModelComponent {}
extension NSPropertyDescription : ObjectModelComponent {}

// define a structure representing a test case for a specific component property;
fileprivate struct Example<T: ObjectModelComponent>
  {
    let name : String
    let effect : (T, T) -> Void

    init(_ name: String, _ effect: @escaping (T, T) -> Void)
      { self.name = name; self.effect = effect }
  }

// and define a method for checking expectations for a list of examples.
fileprivate func testVersionHashes<T: ObjectModelComponent>(_ type: T.Type = T.self, equality: Bool, examples: [Example<T>] = []) throws
  {
    for example in examples {
      let t1 = T.init(), t2 = T.init()
      example.effect(t1, t2)
      if (t1.versionHash == t2.versionHash) != equality {
        XCTFail("unexpected \(equality ? "in" : "")equality for '\(example.name)'")
      }
    }
  }


// Now for each object model component, create two instances which differ in those properties and check the effect on version hash values
extension ModelIdentityTests
  {
    /// For various properties of NSAttributeDescription, create two instances which differ in those properties and check the effect on version hash values.
    func testAttributeVersionHash() throws
      {
        // Changes which affect version hash...
        try testVersionHashes(NSAttributeDescription.self, equality: false, examples: [
          .init("name", {$0.name = "a"; $1.name = "b"}),
          .init("type", {$0.type = .integer16; $1.type = .integer32}),
          .init("isOptional", {$0.isOptional = false; $1.isOptional = true}),
          .init("isTransient", {$0.isTransient = false; $1.isTransient = true}),
          .init("versionHashModifier", {$0.versionHashModifier = nil; $1.versionHashModifier = "x"}),
          .init("allowsExternalBinaryDataStorage", {$0.allowsExternalBinaryDataStorage = false; $1.allowsExternalBinaryDataStorage = true}),
          .init("preservesValueInHistoryOnDeletion", {$0.preservesValueInHistoryOnDeletion = false; $1.preservesValueInHistoryOnDeletion = true}),
        ])

        // Changes which do not affect version hash...
        try testVersionHashes(NSAttributeDescription.self, equality: true, examples: [
          .init("allowsCloudEncryption", {$0.allowsCloudEncryption = false; $1.allowsCloudEncryption = true}),
          .init("attributeValueClassname", {$1.attributeValueClassName = "x"}),
          .init("defaultValue", {$0.defaultValue = nil; $1.defaultValue = 7}),
          .init("isIndexedBySpotlight", {$0.isIndexedBySpotlight = false; $1.isIndexedBySpotlight = true}),
          .init("renamingIdentifier", {$1.renamingIdentifier = "x"}),
          .init("userInfo", {$1.userInfo = ["x": 1]}),
          .init("validationPredicates", {$1.setValidationPredicates([.init(format: "%@ != 0")], withValidationWarnings: ["invalid"])}),
        ])
      }

    /// For various properties of NSRelationshipDescription, create two instances which differ in those properties and check the effect on version hash values.
    func testRelationshipVersionHash() throws
      {
        // Changes which affect version hash...
        try testVersionHashes(NSRelationshipDescription.self, equality: false, examples: [
          .init("name", {$0.name = "r1"; $1.name = "r2"}),
          .init("isOptional", {$0.isOptional = false; $1.isOptional = true}),
          .init("isOrdered", {$0.isOrdered = false; $1.isOrdered = true}),
          .init("isTransient", {$0.isTransient = false; $1.isTransient = true}),
          .init("rangeOfCount", {$0.rangeOfCount = 0 ... 3; $1.rangeOfCount = 0 ... 4}),
          .init("versionHashModifier", {$0.versionHashModifier = nil; $1.versionHashModifier = "x"}),
        ])

        // Changes which do not affect version hash...
        let destinationEntity = NSEntityDescription()
        let inverseRelationship = NSRelationshipDescription()
        try testVersionHashes(NSRelationshipDescription.self, equality: true, examples: [
          .init("deleteRule", {$0.deleteRule = .noActionDeleteRule; $1.deleteRule = .cascadeDeleteRule}),
          .init("destinationEntity", {$1.destinationEntity = destinationEntity}),
          .init("inverseRelationship", {$1.inverseRelationship = inverseRelationship}),
          .init("isIndexedBySpotlight", {$0.isIndexedBySpotlight = false; $1.isIndexedBySpotlight = true}),
          .init("renamingIdentifier", {$1.renamingIdentifier = "x"}),
          .init("userInfo", {$1.userInfo = ["x": 1]}),
        ])
      }

    /// For various properties of NSEntityDescription, create two instances which differ in those properties and check the effect on version hash values.
    func testEntityVersionHash() throws
      {
        // Changes which affect version hash...
        try testVersionHashes(NSEntityDescription.self, equality: false, examples: [
          .init("name", {$0.name = "A"; $1.name = "B"}),
          .init("isAbstract", {$0.isAbstract = false; $1.isAbstract = true}),
          .init("attributes", {$1.properties = [NSAttributeDescription(name: "a")]}),
          .init("relationships", {$1.properties = [NSRelationshipDescription(name: "r")]}),
          .init("versionHashModifier", {$1.versionHashModifier = "x"}),
        ])

        // Changes which do not affect version hash...
        try testVersionHashes(NSEntityDescription.self, equality: true, examples: [
          .init("coreSpotlightDisplayNameExpression", {$1.coreSpotlightDisplayNameExpression = .init(format: "1")}),
          .init("fetchedProperties", {$1.properties = [NSFetchedPropertyDescription(name: "f")]}),
          .init("managedObjectClassName", {$1.managedObjectClassName = "x"}),
          .init("renamingIdentifier", {$1.renamingIdentifier = "x"}),
          .init("userInfo", {$1.userInfo = ["x": 0]}),
        ])
      }
  }
