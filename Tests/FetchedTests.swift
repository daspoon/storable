/*

*/

import XCTest
import CoreData
@testable import Compendium


#if false // NOTE: Swift compiler crashes on the following

@objc(Occupant)
fileprivate class Occupant : Object
  {
    @Attribute("name")
    var name : String

    @Attribute("age")
    var age : Int

    @Relationship("dwelling", inverseName: "items", deleteRule: .nullifyDeleteRule)
    var dwelling : Dwelling?
  }


@objc(Dwelling)
fileprivate class Dwelling : Object
  {
    @Relationship("occupants", inverseName: "dwelling", deleteRule: .nullifyDeleteRule)
    var occupants : Set<Occupant>

    @Fetched("occupantsByName", fetchRequest: makeFetchRequest(sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantsByName : [Occupant]

    @Fetched("minorOccupantsByAge", fetchRequest: makeFetchRequest(predicate: .init(format: "age < 18"), sortDescriptors: [.init(key: "age", ascending: true)]))
    var minorOccupantsByAge : [Occupant]

    @Fetched("occupantIdsByName", fetchRequest: makeFetchRequest(sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantIdsByName : [NSManagedObjectID]

    @Fetched("occupantNamesAndAges", fetchRequest: makeFetchRequest(sortDescriptors: [.init(key: "name", ascending: true)]))
    var occupantNamesAndAges : [[String: Any]]

    @Fetched("numberOfOccupants", fetchRequest: makeFetchRequest())
    var numberOfOccupants : Int
  }


final class FetchedTests : XCTestCase
  {
    func test() throws
      {
        let store = try dataStore(for: [Dwelling.self, Occupant.self])

        let home = try store.create(Dwelling.self) { _ in }
        let dad    = try store.create(Occupant.self) { $0.name = "dad";   $0.age = 35; $0.dwelling = home }
        let mom    = try store.create(Occupant.self) { $0.name = "mom";   $0.age = 34; $0.dwelling = home }
        let jonny  = try store.create(Occupant.self) { $0.name = "jonny"; $0.age =  5; $0.dwelling = home }
        let suzie  = try store.create(Occupant.self) { $0.name = "suzie"; $0.age =  3; $0.dwelling = home }
        let teddy  = try store.create(Occupant.self) { $0.name = "teddy"; $0.age =  1; $0.dwelling = home }

        store.save()

        XCTAssertEqual(home.occupantsByName, [dad, jonny, mom, suzie, teddy])
        XCTAssertEqual(home.minorOccupantsByAge, [teddy, suzie, jonny])
        XCTAssertEqual(home.occupantIdsByName, [dad, jonny, mom, suzie, teddy].map { $0.objectID })
        XCTAssertEqual(home.numberOfOccupants, 5)
      }
  }

#endif
