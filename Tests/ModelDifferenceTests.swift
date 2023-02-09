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

fileprivate class PropertyAddition_v1 : Object
  { }

fileprivate class PropertyAddition_v2 : Object
  {
    @Attribute("a")
    var a : String
    @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
    var r : Object
  }

extension ModelDifferenceTests
  {
    func testPropertyAddition() throws
      {
        try checkDifference(from: PropertyAddition_v1.self, to: PropertyAddition_v2.self, matches: .init(
          attributesDifference: .init(added: ["a"]),
          relationshipsDifference: .init(added: ["r"])
        ))
        try checkDifference(from: PropertyAddition_v2.self, to: PropertyAddition_v1.self, matches: .init(
          attributesDifference: .init(removed: ["a"]),
          relationshipsDifference: .init(removed: ["r"])
        ))
      }
  }


// MARK: --
// Renaming Object properties

fileprivate class PropertyRename_v1 : Object
  {
    @Attribute("a")
    var a : Int
    @Relationship("r", inverseName: "_", deleteRule: .noActionDeleteRule)
    var r : Object
  }

fileprivate class PropertyRename_v2 : Object
  {
    @Attribute("b", previousName: "a")
    var b : Int
    @Relationship("q", inverseName: "_", deleteRule: .noActionDeleteRule, previousName: "r")
    var q : Object
  }

extension ModelDifferenceTests
  {
    // Rename attributes and relationships
    func testPropertyRename() throws
      {
        try checkDifference(from: PropertyRename_v1.self, to: PropertyRename_v2.self, matches: .init(
          attributesDifference: .init(modified: ["b": [.name]]),
          relationshipsDifference: .init(modified: ["q": [.name]])
        ))
      }
  }


// MARK: --
// We can rename a previously-existing property while simultaneously adding a new property with the original name.

fileprivate class PropertyOverride_v1 : Object
  {
    @Attribute("a")
    var a : Int
  }

fileprivate class PropertyOverride_v2 : Object
  {
    @Attribute("b", previousName: "a")
    var b : Int
    @Attribute("a")
    var a : String
  }

extension ModelDifferenceTests
  {
    func testPropertyOverride() throws
      {
        try checkDifference(from: PropertyOverride_v1.self, to: PropertyOverride_v2.self, matches: .init(attributesDifference: .init(
          added: ["a"],
          modified: ["b": [.name]]
        )))
      }
  }


// MARK: --
// Changing attribute optionality

fileprivate class PropertyOptional_v1 : Object
  {
    @Attribute("a")
    var a : Int
  }

fileprivate class PropertyOptional_v2 : Object
  {
    @OptionalAttribute("a")
    var a : Int?
  }

extension ModelDifferenceTests
  {
    func testPropertyOptionality() throws
      {
        try checkDifference(from: PropertyOptional_v1.self, to: PropertyOptional_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
        try checkDifference(from: PropertyOptional_v2.self, to: PropertyOptional_v1.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
      }
  }


// MARK: --
// Changing attribute type

fileprivate class PropertyRetype_v1 : Object
  {
    @Attribute("a")
    var a : Int
  }

fileprivate class PropertyRetype_v2 : Object
  {
    @Attribute("a")
    var a : Float
  }

extension ModelDifferenceTests
  {
    func testPropertyRetype() throws
      {
        try checkDifference(from: PropertyRetype_v1.self, to: PropertyRetype_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.type]])))
      }
  }


// MARK: --
// Changing relationship arity

fileprivate class RelationshipArity_v1 : Object
  {
    @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
    var r : Object
  }

fileprivate class RelationshipArity_v2 : Object
  {
    @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
    var r : Object?
  }

fileprivate class RelationshipArity_v3 : Object
  {
    @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule)
    var r : Set<Object>
  }

extension ModelDifferenceTests
  {
    func testRelationshipArity() throws
      {
        try checkDifference(from: RelationshipArity_v1.self, to: RelationshipArity_v2.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: RelationshipArity_v1.self, to: RelationshipArity_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: RelationshipArity_v2.self, to: RelationshipArity_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
      }
  }


// MARK: --
// Properties renamed in the target must exist in the source.

fileprivate class PropertyRenameUnknown_v1 : Object
  { }

fileprivate class PropertyRenameUnknown_v2 : Object
  {
    @Attribute("a", previousName: "b")
    var a : Int
  }

fileprivate class PropertyRenameUnknown_v3 : Object
  {
    @Relationship("r", inverseName: "q", deleteRule: .noActionDeleteRule, previousName: "s")
    var r : Object
  }

extension ModelDifferenceTests
  {
    func testAttributeRenameUnknown() throws
      { try checkDifferenceFails(from: PropertyRenameUnknown_v1.self, to: PropertyRenameUnknown_v2.self) }

    func testRelationshipRenameUnknown() throws
      { try checkDifferenceFails(from: PropertyRenameUnknown_v1.self, to: PropertyRenameUnknown_v3.self) }
  }


// MARK: --
// Properties renamed in the target must map to distinct properties in the source.

fileprivate class PropertyRenameConflict_v1 : Object
  {
    @Attribute("a")
    var a : Int
  }

fileprivate class PropertyRenameConflict_v2 : Object
  {
    @Attribute("b", previousName: "a")
    var b : Int
    @Attribute("c", previousName: "a")
    var c : Int
  }

extension ModelDifferenceTests
  {
    func testAttributeRenameConflict() throws
      { try checkDifferenceFails(from: PropertyRenameConflict_v1.self, to: PropertyRenameConflict_v2.self) }
  }


// MARK: --
// Adding, removing and modifying entities

fileprivate class Added : Object
  { }

fileprivate class Removed : Object
  { }

fileprivate class Modified_v1 : Object
  { @Attribute("a") var a : Int }

fileprivate class Modified_v2 : Object
  { @Attribute("a") var a : Float }

extension ModelDifferenceTests
  {
    func testEntityAddition() throws
      {
        let s1 = try Schema(name: "", objectTypes: [Removed.self, Modified_v1.self])
        let s2 = try Schema(name: "", objectTypes: [Added.self, Modified_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(
          added: [Added.entityName],
          removed: [Removed.entityName],
          modified: ["Modified": .init(attributesDifference: .init(modified: ["a": [.type]]))!]
        ))
      }
  }


// MARK: --
// Renaming entities

// MARK: --
// Changing entity abstract(ness)


// MARK: --
// Moving properties between inheritance-related entities
