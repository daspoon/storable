/*

  Created by David Spooner

*/

import XCTest
import Storable


final class TransientTests : XCTestCase
  {
    class Thing : NSObject {
      let name : String
      init(name: String) { self.name = name; super.init() }
    }

    @ManagedObject class Object : ManagedObject {
      @Transient var thing1 : Thing
      @Transient var thing2 : Thing = Thing(name: "two")
      @Transient var thing3 : Thing?
    }

    /// We can create and save a model instance when all non-optional transients have assigned values, and we can retrieve the expected values.
    func testCreation() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Object.self]))
        let object = try store.create(Object.self)
        object.thing1 = Thing(name: "one")
        try store.save()

        if object.thing1.name != "one" { XCTFail("") }
        if object.thing2.name != "two" { XCTFail("") }
        if object.thing3?.name != .none { XCTFail("") }
      }

    /// Attempting to save a model instance with an unassigned non-optional transient will fail.
    func testFailToSaveWithUnassignedNonOptionalProperty() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Object.self]))
        _ = try store.create(Object.self)

        let success : Bool
        do {
          try store.save()
          success = false
        }
        catch {
          success = true
        }
        if success == false { XCTFail("") }
      }
  }
