/*

  Created by David Spooner

  Test difference calculations between objects and schemas.

*/

import XCTest
import Storable


final class ModelDifferenceTests : XCTestCase
  {
    // First define some convenience methods for use in subsequent test cases

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


    // Detect property addition and removal
    func testPropertyAddition() throws
      {
        class E_v1 : Entity
          { }

        class E_v2 : Entity
          {
            @Attribute("a")
            var a : String
            @Relationship("r", inverse: "_", deleteRule: .noAction)
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


    // Detect property renaming
    func testPropertyRename() throws
      {
        class E_v1 : Entity
          {
            @Attribute("a")
            var a : Int
            @Relationship("r", inverse: "_", deleteRule: .noAction)
            var r : Entity
          }

        class E_v2 : Entity
          {
            @Attribute("b", renamingIdentifier: "a")
            var b : Int
            @Relationship("q", inverse: "_", deleteRule: .noAction, renamingIdentifier: "r")
            var q : Entity
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(
          attributesDifference: .init(modified: ["b": [.name]]),
          relationshipsDifference: .init(modified: ["q": [.name]])
        ))
      }


    // We can rename a previously-existing property while simultaneously adding a new property with the original name.
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


    // Detect changing attribute optionality
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


    // Detect changing attribute type
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


    // Detect changing relationship range
    func testRelationshipRange() throws
      {
        class E_v1 : Entity
          {
            @Relationship("r", inverse: "q", deleteRule: .noAction)
            var r : Entity
          }

        class E_v2 : Entity
          {
            @Relationship("r", inverse: "q", deleteRule: .noAction)
            var r : Entity?
          }

        class E_v3 : Entity
          {
            @Relationship("r", inverse: "q", deleteRule: .noAction)
            var r : Set<Entity>
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v1.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v2.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
      }


    // Attributes renamed in the target must exist in the source.
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


    // Relationships renamed in the target must exist in the source.
    func testRelationshipRenameUnknown() throws
      {
        class E_v1 : Entity
          { }

        class E_v2 : Entity
          {
            @Relationship("r", inverse: "q", deleteRule: .noAction, renamingIdentifier: "s")
            var r : Entity
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }


    // Properties renamed in the target must map to distinct properties in the source.
    func testAttributeRenameConflict() throws
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
            @Attribute("c", renamingIdentifier: "a")
            var c : Int
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }


    // Detect added, removed and modified entities
    func testEntityAddition() throws
      {
        class Added : Entity
          { }

        class Removed : Entity
          { }

        class Modified_v1 : Entity
          { @Attribute("a") var a : Int }

        class Modified_v2 : Entity
          { @Attribute("a") var a : Float }

        let s1 = try Schema(objectTypes: [Removed.self, Modified_v1.self])
        let s2 = try Schema(objectTypes: [Added.self, Modified_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(
          added: [Added.entityName],
          removed: [Removed.entityName],
          modified: ["Modified": .init(attributesDifference: .init(modified: ["a": [.type]]))!]
        ))
      }


    // Detect renamed entities
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


    // Detect changing entity abstract(ness)
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