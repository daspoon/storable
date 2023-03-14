/*

*/

import XCTest
@testable import Storable


final class StorableTests: XCTestCase
  {
    func testExample() throws
      {
        @Entity
        class Thing : Entity {
          @Attribute var intValue : Int
          @Attribute var stringValue : String
        }

        var s = Thing()
        s.intValue = 5
        s.stringValue = "heynow"
        _ = s.intValue
        _ = s.stringValue
      }
  }
