/*

  Test our assumptions about various CoreData behaviors.

*/

import XCTest
import CoreData


final class CoreDataTests : XCTestCase
  {  }


// MARK: --

// The following tests show which properties of NSAttributeDescription, NSRelationshipDescription and NSEntityDescription affect their versionHash. The general form of each test is to create two instances of each component which differ in the value of a chosen property and to assert the effect on the version hashes.

extension CoreDataTests
  {
    /// A convenience structure representing an example change for a specific component and property.
    struct Example<T: ObjectModelComponent>
      {
        let name : String
        let effect : (T, T) -> Void

        init(_ name: String, _ effect: @escaping (T, T) -> Void)
          { self.name = name; self.effect = effect }
      }

    /// A convenience method for checking expectations for a list of Examples.
    func testVersionHashes<T: ObjectModelComponent>(_ type: T.Type = T.self, equality: Bool, examples: [Example<T>] = []) throws
      {
        for example in examples {
          let t1 = T.init(), t2 = T.init()
          example.effect(t1, t2)
          if (t1.versionHash == t2.versionHash) != equality {
            XCTFail("unexpected \(equality ? "in" : "")equality for '\(example.name)'")
          }
        }
      }

    /// Show relevant properties of NSAttributeDescription.
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

    /// Show relevant properties of NSRelationshipDescription.
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

    /// Show relevant properties of NSEntityDescription.
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


// MARK: --

// The following tests demonstrate how various property renaming scenarios affect mapping model inferrence. Each test creates source and target object models with a single same-named entity, then attempts to infer a mapping between the models.

extension CoreDataTests
  {
    /// A convenience method for checking expected compatibility between two given entities.
    func ensureModelInferrence(succeeds: Bool, from sourceEntity: NSEntityDescription, to targetEntity: NSEntityDescription) throws
      {
        precondition(sourceEntity.name == targetEntity.name)

        let sourceModel = NSManagedObjectModel(entities: [sourceEntity])
        let targetModel = NSManagedObjectModel(entities: [targetEntity])
        do {
          _ = try NSMappingModel.inferredMappingModel(forSourceModel: sourceModel, destinationModel: targetModel)
          guard succeeds == true else { XCTFail("failed to generate exception"); return }
        }
        catch let error {
          guard succeeds == false else { XCTFail("\(error)"); return }
        }
      }

    /// A simple example where renaming is expected to succeed.
    func testRenamingBasic() throws
      {
        try ensureModelInferrence(succeeds: true,
              from: NSEntityDescription(name: "E") { $0.properties = [NSAttributeDescription(name: "a")] },
              to: NSEntityDescription(name: "E") {
                $0.properties = [ NSAttributeDescription(name: "b") { $0.renamingIdentifier = "a" } ]
              })
      }

    /// CoreData doesn't mind if the source model does not have a property of the specified name.
    func testRenamingToUnknown() throws
      {
        try ensureModelInferrence(succeeds: true,
              from: NSEntityDescription(name: "E"),
              to: NSEntityDescription(name: "E") {
                $0.properties = [ NSAttributeDescription(name: "b") { $0.renamingIdentifier = "a" } ]
              })
      }

    /// CoreData requires a renamed property to have the same type as the original.
    func testRenamingPreservesType() throws
      {
        try ensureModelInferrence(succeeds: false,
              from: NSEntityDescription(name: "E") { $0.properties = [NSAttributeDescription(name: "a")] },
              to: NSEntityDescription(name: "E") {
                $0.properties = [ NSAttributeDescription(name: "b") { $0.renamingIdentifier = "a"; $0.type = .float } ]
              })
      }

    /// CoreData doesn't mind if multiple target properties are marked as renaming of the same source property -- provided their types are consistent.
    func testRenamingDuplicates() throws
      {
        try ensureModelInferrence(succeeds: true,
              from: NSEntityDescription(name: "E") { $0.properties = [NSAttributeDescription(name: "a")] },
              to: NSEntityDescription(name: "E") {
                $0.properties = [
                  NSAttributeDescription(name: "a"),
                  NSAttributeDescription(name: "b") { $0.renamingIdentifier = "a" },
                  NSAttributeDescription(name: "c") { $0.renamingIdentifier = "a" },
                ]
              })

        try ensureModelInferrence(succeeds: false,
              from: NSEntityDescription(name: "E") { $0.properties = [NSAttributeDescription(name: "a")] },
              to: NSEntityDescription(name: "E") {
                $0.properties = [
                  NSAttributeDescription(name: "a"),
                  NSAttributeDescription(name: "b") { $0.renamingIdentifier = "a"; $0.type = .float },
                ]
              })
      }
  }
