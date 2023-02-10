/*

  Test difference calculations between objects and schemas.

*/

import XCTest
import Compendium


// First define the test class and some convenience methods.

final class ModelDifferenceTests : XCTestCase
  {
    func difference(from old: Object.Type, to new: Object.Type) throws -> ObjectInfo.Difference?
      {
        let oldInfo = try ObjectInfo(objectType: old)
        let newInfo = try ObjectInfo(objectType: new)
        return try newInfo.difference(from: oldInfo)
      }

    func checkDifference(from old: Object.Type, to new: Object.Type, matches expectedDifference: ObjectInfo.Difference?) throws
      {
        XCTAssertEqual(try difference(from: old, to: new), expectedDifference)
      }

    func checkDifferenceFails(from old: Object.Type, to new: Object.Type/*, with: ... */) throws
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
// Adding and removing Object properties

extension ModelDifferenceTests
  {
    func testPropertyAddition() throws
      {
        class Entity_v1 : Object
          { }

        class Entity_v2 : Object
          {
            @Attribute("a")
            var a : String
            @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
            var r : Object
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(
          attributesDifference: .init(added: ["a"]),
          relationshipsDifference: .init(added: ["r"])
        ))

        try checkDifference(from: Entity_v2.self, to: Entity_v1.self, matches: .init(
          attributesDifference: .init(removed: ["a"]),
          relationshipsDifference: .init(removed: ["r"])
        ))
      }
  }


// MARK: --
// Renaming Object properties

extension ModelDifferenceTests
  {
    // Rename attributes and relationships
    func testPropertyRename() throws
      {
        class Entity_v1 : Object
          {
            @Attribute("a")
            var a : Int
            @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
            var r : Object
          }

        class Entity_v2 : Object
          {
            @Attribute("b", previousName: "a")
            var b : Int
            @Relationship("q", inverseName: "_", deleteRule: .noActionDeleteRule, previousName: "r")
            var q : Object
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(
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
        class Entity_v1 : Object
          {
            @Attribute("a")
            var a : Int
          }

        class Entity_v2 : Object
          {
            @Attribute("b", previousName: "a")
            var b : Int
            @Attribute("a")
            var a : String
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(attributesDifference: .init(
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
        class Entity_v1 : Object
          {
            @Attribute("a")
            var a : Int
          }

        class Entity_v2 : Object
          {
            @OptionalAttribute("a")
            var a : Int?
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
        try checkDifference(from: Entity_v2.self, to: Entity_v1.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
      }
  }


// MARK: --
// Changing attribute type

extension ModelDifferenceTests
  {
    func testPropertyRetype() throws
      {
        class Entity_v1 : Object
          {
            @Attribute("a")
            var a : Int
          }

        class Entity_v2 : Object
          {
            @Attribute("a")
            var a : Float
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.type]])))
      }
  }


// MARK: --
// Changing relationship arity

extension ModelDifferenceTests
  {
    func testRelationshipArity() throws
      {
        class Entity_v1 : Object
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Object
          }

        class Entity_v2 : Object
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Object?
          }

        class Entity_v3 : Object
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
            var r : Set<Object>
          }

        try checkDifference(from: Entity_v1.self, to: Entity_v2.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: Entity_v1.self, to: Entity_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: Entity_v2.self, to: Entity_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
      }
  }


// MARK: --
// Properties renamed in the target must exist in the source.

extension ModelDifferenceTests
  {
    func testAttributeRenameUnknown() throws
      {
        class Entity_v1 : Object
          { }

        class Entity_v2 : Object
          {
            @Attribute("a", previousName: "b")
            var a : Int
          }

        try checkDifferenceFails(from: Entity_v1.self, to: Entity_v2.self)
      }

    func testRelationshipRenameUnknown() throws
      {
        class Entity_v1 : Object
          { }

        class Entity_v2 : Object
          {
            @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule, previousName: "s")
            var r : Object
          }

        try checkDifferenceFails(from: Entity_v1.self, to: Entity_v2.self)
      }
  }


// MARK: --
// Properties renamed in the target must map to distinct properties in the source.

extension ModelDifferenceTests
  {
    func testAttributeRenameConflict() throws
      {
        @objc class Entity_v1 : Object
          {
            @Attribute("a")
            var a : Int
          }

        @objc class Entity_v2 : Object
          {
            @Attribute("b", previousName: "a")
            var b : Int
            @Attribute("c", previousName: "a")
            var c : Int
          }

        try checkDifferenceFails(from: Entity_v1.self, to: Entity_v2.self)
      }
  }


// MARK: --
// Adding, removing and modifying entities

extension ModelDifferenceTests
  {
    func testEntityAddition() throws
      {
        @objc class Added : Object
          { }

        @objc class Removed : Object
          { }

        @objc class Modified_v1 : Object
          { @Attribute("a") var a : Int }

        @objc class Modified_v2 : Object
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
        class Old : Object {
        }

        class New : Object {
          override class var previousEntityName : String? { "Old" }
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
        class Entity_v1 : Object {
        }

        class Entity_v2 : Object {
          override class var abstractClass : Object.Type { Entity_v2.self }
        }

        let s1 = try Schema(objectTypes: [Entity_v1.self])
        let s2 = try Schema(objectTypes: [Entity_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(modified: ["Entity": .init(descriptorChanges: [.isAbstract])!]))
      }
  }


// MARK: --
// Moving properties between inheritance-related entities

extension ModelDifferenceTests
  {
    // TODO:
  }
