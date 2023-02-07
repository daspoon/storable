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

// The following tests demonstrate how various scenarios affect mapping model inferrence. Each test creates source and target object models with a single same-named entity, then attempts to infer a mapping between the models.

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

    /// We can add an attribute regardless of its optionality.
    func testAttributeAddition() throws
      {
        try ensureModelInferrence(succeeds: true,
          from: NSEntityDescription(name: "E"),
          to: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .transformable) {$0.isOptional = false}]}
        )
        try ensureModelInferrence(succeeds: true,
          from: NSEntityDescription(name: "E"),
          to: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = true}]}
        )
      }

    /// We can change an attribute's optionality.
    func testAttributeChangeOptionality() throws
      {
        try ensureModelInferrence(succeeds: true,
          from: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = true}]},
          to: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = false}]}
        )
        try ensureModelInferrence(succeeds: true,
          from: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = false}]},
          to: NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = true}]}
        )
      }
  }


// MARK: --

@testable import Compendium


extension CoreDataTests
  {
    @nonobjc func performLightweightMigration(at storeURL: URL, from source: NSManagedObjectModel, to target: NSManagedObjectModel) throws
      {
        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: target)
        let manager = NSMigrationManager(sourceModel: source, destinationModel: target)
        try manager.migrateStore(from: storeURL, type: .sqlite, mapping: mapping, to: storeURL, type: .sqlite)
      }

    @nonobjc func performLightweightMigration(at storeURL: URL, from sourceEntity: NSEntityDescription, to targetEntity: NSEntityDescription) throws
      {
        let sourceModel = NSManagedObjectModel(entities: [sourceEntity.copy() as! NSEntityDescription])
        let targetModel = NSManagedObjectModel(entities: [targetEntity.copy() as! NSEntityDescription])
        try performLightweightMigration(at: storeURL, from: sourceModel, to: targetModel)
      }

    @nonobjc func updateStore(at storeURL: URL, as model: NSManagedObjectModel, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        _ = try coordinator.addPersistentStore(type: .sqlite, at: storeURL)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        try script(context)
        try context.save()
      }

    @nonobjc func updateStore(at storeURL: URL, as entity: NSEntityDescription, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        let model = NSManagedObjectModel(entities: [entity.copy() as! NSEntityDescription])
        try updateStore(at: storeURL, as: model, using: script)
      }


    /// Adding a non-optional attribute (with no default) value requires more than lightweight migration.
    func testMigrateAddAttributeFail() throws
      {
        // The purpose of this test is to clarify the distinction between mapping model inference and lightweight migration: while CoreData will always infer a mapping model for property addition, performing a lightweight/in-place migration requires that the resulting store be consistent with the target object model -- i.e. all non-optional properties have assigned values.

        // Create a base entity E and derivative E1 which adds a non-optional property of the same name and type with no default value.
        let E  = NSEntityDescription(name: "E")
        let E1 = NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .integer64) {$0.isOptional = false}]}

        // Create a store containing some instances of E.
        repeat {
          let store = try DataStore(name: "test", managedObjectModel: NSManagedObjectModel(entities: [E]), reset: true)
          let _ = NSManagedObject(entity: E, insertInto: store.managedObjectContext)
          let _ = NSManagedObject(entity: E, insertInto: store.managedObjectContext)
          try store.save()
        } while false

        // Although CoreData will infer a mapping model,
        let source = NSManagedObjectModel(entities: [NSEntityDescription(name: "E")])
        let target = NSManagedObjectModel(entities: [E1])
        let mapping = try NSMappingModel.inferredMappingModel(forSourceModel: source, destinationModel: target)

        // it can't peform a lightweight/in-place migration...
        let storeURL = try DataStore.storeURL(forName: "test")
        do {
          let manager = NSMigrationManager(sourceModel: source, destinationModel: target)
          try manager.migrateStore(from: storeURL, type: .sqlite, mapping: mapping, to: storeURL, type: .sqlite)
          XCTFail("failed to fail")
        }
        catch let error as NSError {
          XCTAssert(error.domain == NSCocoaErrorDomain && error.code == NSMigrationError)
        }
      }

    /// Adding a non-optional attribute requires multiple steps.
    func testMigrateAddAttribute() throws
      {
        // The purpose of this test is illustrate the multi-step process for general property addition: 1) create an intermediate model which adds optional variants of the properties to the source model; 2) perform a lightweight migration from source to intermediate model; 3) open the store and assign values to all property instances; 4) perform lightweight migration to the target model.

        // Create a base entity E with derivatives E1 and E2 which add a property of the same name and type, one optional and the other non-optional.
        let E  = NSEntityDescription(name: "E")
        let E1 = NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .integer64) {$0.isOptional = true}]}
        let E2 = NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .integer64) {$0.isOptional = false}]}

        // Create a store containing some instances of E.
        let objectCount = 3
        repeat {
          let store = try DataStore(name: "test", managedObjectModel: NSManagedObjectModel(entities: [E]), reset: true)
          for _ in 0 ..< objectCount {
            _ = NSManagedObject(entity: E, insertInto: store.managedObjectContext)
          }
          try store.save()
        } while false

        // Open the store (with implicit lightweight migration) as E1, assign values to all property instances, and save the store.
        repeat {
          let store = try DataStore(name: "test", managedObjectModel: NSManagedObjectModel(entities: [E1]), reset: false)
          let objects = try store.managedObjectContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "E"))
          XCTAssert(objects.count == objectCount)
          for (i, object) in objects.enumerated() {
            object.setValue(i, forKey: "a")
          }
          try store.save()
        } while false

        // Open the store as E2.
        repeat {
          let store = try DataStore(name: "test", managedObjectModel: NSManagedObjectModel(entities: [E2]), reset: false)
          let objects = try store.managedObjectContext.fetch(NSFetchRequest<NSManagedObject>(entityName: "E"))
          XCTAssert(objects.count == objectCount)
        } while false
      }

    /// Changing an attribute's storage type requires multiple steps.
    func testMigrateTypeChange() throws
      {
        // A 3-step process is required to change an attribute's storage type.

        let storeURL = try! DataStore.storeURL(forName: "test")

        // Create source and target entities which define non-optional attribute a as int and string respectively.
        let Es = NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .integer64) {$0.isOptional = false}]}
        let Et = NSEntityDescription(name: "E") {$0.properties = [NSAttributeDescription(name: "a", type: .string) {$0.isOptional = false}]}

        // Create a store containing some instances of Es.
        let objectCount = 3
        repeat {
          let store = try DataStore(name: "test", managedObjectModel: NSManagedObjectModel(entities: [Es]), reset: true)
          for i in 0 ..< objectCount{
            let obj = NSManagedObject(entity: Es, insertInto: store.managedObjectContext)
            obj.setValue(i, forKey: "a")
          }
          try store.save()
        } while false

        // We must first rename the affected attribute (preserving its type) and add a new attribute (distinctly named) with the new type, but optional.
        let Ei = NSEntityDescription(name: "E") {$0.properties = [
          NSAttributeDescription(name: "$a_old", type: .integer64) {$0.isOptional = false; $0.renamingIdentifier = "a"},
          NSAttributeDescription(name: "$a_new", type: .string) {$0.isOptional = true},
        ]}
        try performLightweightMigration(at: storeURL, from: Es, to: Ei)

        // Then run a script to assign values for the new attribute.
        try updateStore(at: storeURL, as: Ei) { context in
          let objects = try context.fetch(NSFetchRequest<NSManagedObject>(entityName: "E"))
          XCTAssert(objects.count == objectCount)
          for object in objects {
            let i = object.value(forKey: "$a_old") as! Int
            object.setValue("\(i)", forKey: "$a_new")
          }
        }

        // The target entity must specify the renaming
        Et.attributesByName["a"]!.renamingIdentifier = "$a_new"

        // Finally we can migrate to the target model.
        try performLightweightMigration(at: storeURL, from: Ei, to: Et)
      }
  }
