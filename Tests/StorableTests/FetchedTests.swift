/*

  Created by David Spooner

  Test expected behavior of fetched properties.

*/

import XCTest
import CoreData
import Storable


@ManagedObject fileprivate class Occupant : ManagedObject
  {
    @Attribute
    var name : String

    @Attribute
    var age : Int

    @Relationship(inverse: "occupants", deleteRule: .nullify)
    var dwelling : Dwelling?
  }



@ManagedObject fileprivate class Dwelling : ManagedObject
  {
    @Relationship(inverse: "dwelling", deleteRule: .nullify)
    var occupants : Set<Occupant>

    @Fetched(predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)])
    var occupantsByName : [Occupant]

    @Fetched(predicate: .init(format: "dwelling = $FETCH_SOURCE && age < 18"), sortDescriptors: [.init(key: "age", ascending: true)])
    var minorOccupantsByAge : [Occupant]

    @Fetched(identifiersOf: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)])
    var occupantIdsByName : [NSManagedObjectID]

    @Fetched(dictionariesOf: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE"), sortDescriptors: [.init(key: "name", ascending: true)])
    var occupantNamesAndAges : [[String: Any]]

    @Fetched(countOf: Occupant.self, predicate: .init(format: "dwelling = $FETCH_SOURCE"))
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

        if flintstone.occupantsByName != [fred, pebbles, wilma] { XCTFail("flintstone.occupantsByName") }
        if flintstone.minorOccupantsByAge != [pebbles] { XCTFail("flintstone.minorOccupantsByAge") }
        if rubble.occupantIdsByName != [bambam, barney, betty].map({$0.objectID}) { XCTFail("rubble.occupantIdsByName") }
        if flintstone.numberOfOccupants != 3 { XCTFail("flintstone.numberOfOccupants") }
      }
  }
