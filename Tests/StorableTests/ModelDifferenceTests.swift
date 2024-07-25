/*

  Created by David Spooner

  Test difference calculations between objects and schemas.

*/

import XCTest
@testable import Storable


final class ModelDifferenceTests : XCTestCase
  {
    // First define some convenience methods for use in subsequent test cases

    func difference(from old: ManagedObject.Type, to new: ManagedObject.Type) throws -> Entity.Difference?
      {
        let oldInfo = try Entity(objectType: old)
        let newInfo = try Entity(objectType: new)
        return try newInfo.difference(from: oldInfo)
      }

    func checkDifference(from old: ManagedObject.Type, to new: ManagedObject.Type, matches expectedDifference: Entity.Difference?) throws
      {
        if try difference(from: old, to: new) != expectedDifference { XCTFail("") }
      }

    func checkDifferenceFails(from old: ManagedObject.Type, to new: ManagedObject.Type/*, with: ... */) throws
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
        if try new.difference(from: old) != expectedDifference { XCTFail("") }
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
        @ManagedObject class E_v1 : ManagedObject
          { }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute
            var a : String
            @Relationship(inverse: "_", deleteRule: .noAction)
            var r : ManagedObject
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
        @ManagedObject class E_v1 : ManagedObject
          {
            @Attribute
            var a : Int
            @Relationship(inverse: "_", deleteRule: .noAction)
            var r : ManagedObject
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute(renamingIdentifier: "a")
            var b : Int
            @Relationship(inverse: "_", deleteRule: .noAction, renamingIdentifier: "r")
            var q : ManagedObject
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(
          attributesDifference: .init(modified: ["b": [.name]]),
          relationshipsDifference: .init(modified: ["q": [.name]])
        ))
      }


    // We can rename a previously-existing property while simultaneously adding a new property with the original name.
    func testPropertyOverride() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          {
            @Attribute
            var a : Int
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute(renamingIdentifier: "a")
            var b : Int
            @Attribute
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
        @ManagedObject class E_v1 : ManagedObject
          {
            @Attribute var a : Int
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute var a : Int?
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
        try checkDifference(from: E_v2.self, to: E_v1.self, matches: .init(attributesDifference: .init(modified: ["a": [.isOptional]])))
      }


    // Detect changing attribute type
    func testPropertyRetype() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          {
            @Attribute
            var a : Int
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute
            var a : Float
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(attributesDifference: .init(modified: ["a": [.type]])))
      }


    // Detect changing relationship range
    func testRelationshipRange() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          {
            @Relationship(inverse: "q", deleteRule: .noAction)
            var r : ManagedObject
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Relationship(inverse: "q", deleteRule: .noAction)
            var r : ManagedObject?
          }

        @ManagedObject class E_v3 : ManagedObject
          {
            @Relationship(inverse: "q", deleteRule: .noAction)
            var r : Set<ManagedObject>
          }

        try checkDifference(from: E_v1.self, to: E_v2.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v1.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
        try checkDifference(from: E_v2.self, to: E_v3.self, matches: .init(relationshipsDifference: .init(modified: ["r": [.rangeOfCount]])))
      }


    // Attributes renamed in the target must exist in the source.
    func testAttributeRenameUnknown() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          { }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute(renamingIdentifier: "b")
            var a : Int
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }


    // Relationships renamed in the target must exist in the source.
    func testRelationshipRenameUnknown() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          { }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Relationship(inverse: "q", deleteRule: .noAction, renamingIdentifier: "s")
            var r : ManagedObject
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }


    // Properties renamed in the target must map to distinct properties in the source.
    func testAttributeRenameConflict() throws
      {
        @ManagedObject class E_v1 : ManagedObject
          {
            @Attribute
            var a : Int
          }

        @ManagedObject class E_v2 : ManagedObject
          {
            @Attribute(renamingIdentifier: "a")
            var b : Int
            @Attribute(renamingIdentifier: "a")
            var c : Int
          }

        try checkDifferenceFails(from: E_v1.self, to: E_v2.self)
      }


    // Detect added, removed and modified entities
    func testEntityAddition() throws
      {
        @ManagedObject class Added : ManagedObject
          { }

        @ManagedObject class Removed : ManagedObject
          { }

        @ManagedObject class Modified_v1 : ManagedObject
          { @Attribute var a : Int }

        @ManagedObject class Modified_v2 : ManagedObject
          { @Attribute var a : Float }

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
        @ManagedObject class Old : ManagedObject {
        }

        @ManagedObject class New : ManagedObject {
          override class var renamingIdentifier : String? { "Old" }
        }

        let s1 = try Schema(objectTypes: [Old.self])
        let s2 = try Schema(objectTypes: [New.self])
        try checkDifference(from: s1, to: s2, matches: .init(modified: ["New": .init(descriptorChanges: [.name])!]))
      }


    // Detect changing entity abstract(ness)
    func testEntityAbstraction() throws
      {
        class E_v1 : ManagedObject {
        }

        class E_v2 : ManagedObject {
          override class var abstractClass : ManagedObject.Type { E_v2.self }
        }

        let s1 = try Schema(objectTypes: [E_v1.self])
        let s2 = try Schema(objectTypes: [E_v2.self])
        try checkDifference(from: s1, to: s2, matches: .init(modified: ["E": .init(descriptorChanges: [.isAbstract])!]))
      }
  }
