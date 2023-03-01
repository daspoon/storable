/*

  Test difference calculations between objects and schemas.

*/

import XCTest
import Compendium


// First define the test class and some convenience methods.

final class ModelDifferenceTests : XCTestCase
  {
    func difference(from old: Entity.Type, to new: Entity.Type) throws -> EntityInfo.Difference?
      {
        let oldInfo = try EntityInfo(objectType: old)
        let newInfo = try EntityInfo(objectType: new)
        return try newInfo.difference(from: oldInfo)
      }

    func checkDifference(from old: Entity.Type, to new: Entity.Type, matches expectedDifference: EntityInfo.Difference?) throws
      {
        XCTAssertEqual(try difference(from: old, to: new), expectedDifference)
      }

    func checkDifferenceFails(from old: Entity.Type, to new: Entity.Type/*, with: ... */) throws
      {
        do {
          _ = try difference(from: old, to: new)
          XCTFail("failed to detect error")
        }
        catch let error as Exception {
          print(error)
        }
      }

    func checkDifference(from old: Schema, to new: Schema, matches expectedDifference: Schema.Difference?) throws
      {
        XCTAssertEqual(try new.difference(from: old), expectedDifference)
      }

    func checkDifferenceFails(from old: Schema, to new: Schema/*, with: ... */) throws
      {
        do {
          _ = try new.difference(from: old)
          XCTFail("failed to detect error")
        }
        catch let error as Exception {
          print(error)
        }
      }
  }


// MARK: --
// Adding and removing Entity properties

extension ModelDifferenceTests
  {
    func testPropertyAddition() throws
      {
        class E_v1 : Entity
          { }

        class E_v2 : Entity
          {
            @Attribute("a")
            var a : String
            @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
            var r : Entity
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(
          attributesDifference: .init(added: ["a"]),
          relationshipsDifference: .init(added: ["r"])
        ))

        try checkDifference(from: E_v2.self, to: E_v1.self, matches: .init(
          attributesDifference: .init(removed: ["a"]),
          relationshipsDifference: .init(removed: ["r"])
        ))
      }
  }


// MARK: --
// Renaming Entity properties

extension ModelDifferenceTests
  {
    // Rename attributes and relationships
    func testPropertyRename() throws
      {
        class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
            @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
            var r : Entity
          }

        class E_v2 : Entity
          {
            @Attribute("b", renamingIdentifier: "a")
            var b : Int
            @Relationship("q", inverseName: "_", deleteRule: .noActionDeleteRule, renamingIdentifier: "r")
            var q : Entity
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(
          attributesDifference: .init(modified: ["b": [.name]]),
          relationshipsDifference: .init(modified: ["q": [.name]])
        ))
      }
  }


// MARK: --
// We can rename a previously-existing property while simultaneously adding a new property with the original name.

extension ModelDifferenceTests
  {
    func testPropertyOverride() throws
      {
        class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
          }

        class E_v2 : Entity
          {
            @Attribute("b", renamingIdentifier: "a")
            var b : Int
            @Attribute("a")
            var a : String
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(attributesDifference: .init(
          added: ["a"],
          modified: ["b": [.name]]
        )))
      }
  }


// MARK: --
// Changing attribute optionality

extension ModelDifferenceTests
  {
    func testPropertyOptionality() throws
      {
        class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
          }

        class E_v2 : Entity
          {
            @OptionalAttribute("a")
            var a : Int?
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
        try checkDifference(from: E_v2.self, to: E_v1.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
      }
  }


// MARK: --
// Changing attribute type

extension ModelDifferenceTests
  {
    func testPropertyRetype() throws
      {
        class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
          }

        class E_v2 : Entity
          {
            @Attribute("a")
            var a : Float
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.type]])))
      }
  }


// MARK: --
// Changing relationship arity

extension ModelDifferenceTests
  {
    func testRelationshipArity() throws
      {
        class E_v1 : Entity
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Entity
          }

        class E_v2 : Entity
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Entity?
          }

        class E_v3 : Entity
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Set<Entity>
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v1.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v2.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
      }
  }


// MARK: --
// Properties renamed in the target must exist in the source.

extension ModelDifferenceTests
  {
    func testAttributeRenameUnknown() throws
      {
        class E_v1 : Entity
          { }

        class E_v2 : Entity
          {
            @Attribute("a", renamingIdentifier: "b")
            var a : Int
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }

    func testRelationshipRenameUnknown() throws
      {
        class E_v1 : Entity
          { }

        class E_v2 : Entity
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule, renamingIdentifier: "s")
            var r : Entity
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }
  }


// MARK: --
// Properties renamed in the target must map to distinct properties in the source.

extension ModelDifferenceTests
  {
    func testAttributeRenameConflict() throws
      {
        @objc class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
          }

        @objc class E_v2 : Entity
          {
            @Attribute("b", renamingIdentifier: "a")
            var b : Int
            @Attribute("c", renamingIdentifier: "a")
            var c : Int
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }
  }


// MARK: --
// Adding, removing and modifying entities

extension ModelDifferenceTests
  {
    func testEntityAddition() throws
      {
        @objc class Added : Entity
          { }

        @objc class Removed : Entity
          { }

        @objc class Modified_v1 : Entity
          { @Attribute("a") var a : Int }

        @objc class Modified_v2 : Entity
          { @Attribute("a") var a : Float }

        let s1 = try Schema(objectTypes: [Removed.self, Modified_v1.self])
        let s2 = try Schema(objectTypes: [Added.self, Modified_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(
          added: [Added.entityName],
          removed: [Removed.entityName],
          modified: ["Modified": .init(attributesDifference: .init(modified: ["a": [.type]]))!]
        ))
      }
  }


// MARK: --
// Renaming entities

extension ModelDifferenceTests
  {
    func testEntityRename() throws
      {
        class Old : Entity {
        }

        class New : Entity {
          override class var renamingIdentifier : String? { "Old" }
        }

        let s1 = try Schema(objectTypes: [Old.self])
        let s2 = try Schema(objectTypes: [New.self])
        try checkDifference(from: s1, to: s2, matches: .init(modified: ["New": .init(descriptorChanges: [.name])!]))
      }
  }


// MARK: --
// Changing entity abstract(ness)

extension ModelDifferenceTests
  {
    func testEntityAbstraction() throws
      {
        class E_v1 : Entity {
        }

        class E_v2 : Entity {
          override class var abstractClass : Entity.Type { E_v2.self }
        }

        let s1 = try Schema(objectTypes: [E_v1.self])
        let s2 = try Schema(objectTypes: [E_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(modified: ["E": .init(descriptorChanges: [.isAbstract])!]))
      }
  }


// MARK: --
// Moving properties between inheritance-related entities

extension ModelDifferenceTests
  {
    // TODO:
  }
