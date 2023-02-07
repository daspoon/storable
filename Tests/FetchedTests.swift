/*

*/

import XCTest
import CoreData
@testable import Compendium


@objc(Occupant)
fileprivate class Occupant : Object
  {
    @Attribute("name")
    var name : String

    @Attribute("age")
    var age : Int

    @Relationship("dwelling", inverseName: "occupants", deleteRule: .nullifyDeleteRule)
    var dwelling : Dwelling?
  }


@objc(Dwelling)
fileprivate class Dwelling : Object
  {
    @Relationship("occupants", inverseName: "dwelling", deleteRule: .nullifyDeleteRule)
    var occupants : Set<Occupant>

    @FetchedProperty("occupantsByName", fetchRequest: makeFetchRequest(predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantsByName : [Occupant]

    @FetchedProperty("minorOccupantsByAge", fetchRequest: makeFetchRequest(predicate: .init(format: "dwelling = $FETCH_SOURCE && age < 18"), sortDescriptors: [.init(key: "age", ascending: true)]))
    var minorOccupantsByAge : [Occupant]

    @FetchedProperty("occupantIdsByName", fetchRequest: makeFetchRequest(for: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantIdsByName : [NSManagedObjectID]

    @FetchedProperty("occupantNamesAndAges", fetchRequest: makeFetchRequest(for: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantNamesAndAges : [[String: Any]]

    @FetchedProperty("numberOfOccupants", fetchRequest: makeFetchRequest(for: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE")))
    var numberOfOccupants : Int
  }


final class FetchedTests : XCTestCase
  {
    func test() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Dwelling.self, Occupant.self]))

        let flintstone = try store.create(Dwelling.self) { _ in }
        let fred    = try store.create(Occupant.self) { $0.name = "fred";    $0.age = 35; $0.dwelling = flintstone }
        let wilma   = try store.create(Occupant.self) { $0.name = "wilma";   $0.age = 34; $0.dwelling = flintstone }
        let pebbles = try store.create(Occupant.self) { $0.name = "pebbles"; $0.age =  3; $0.dwelling = flintstone }
        let rubble  = try store.create(Dwelling.self) { _ in }
        let barney  = try store.create(Occupant.self) { $0.name = "barney";  $0.age = 33; $0.dwelling = rubble }
        let betty   = try store.create(Occupant.self) { $0.name = "betty";   $0.age = 32; $0.dwelling = rubble }
        let bambam  = try store.create(Occupant.self) { $0.name = "bambam";  $0.age =  2; $0.dwelling = rubble }

        try store.save()

        XCTAssertEqual(flintstone.occupantsByName, [fred, pebbles, wilma])
        XCTAssertEqual(flintstone.minorOccupantsByAge, [pebbles])
        XCTAssertEqual(rubble.occupantIdsByName, [bambam, barney, betty].map { $0.objectID })
        XCTAssertEqual(flintstone.numberOfOccupants, 3)
      }
  }
