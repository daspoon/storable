/*

  Ensure the underlying names specified by property wrappers are distinct within the generated entity (accounting for inheritance).

*/

import XCTest
@testable import Compendium


// MARK: -

@objc(PropertyNameConflict)
fileprivate class PropertyNameConflict : Object
  {
    @Attribute("name")
    var firstName : String

    @Attribute("name")
    var lastName : String
  }


// MARK: -

@objc(Super)
fileprivate class Super : Object
  {
    @Attribute("id")
    var id : String
  }

@objc(InhertiedPropertyNameConflict)
fileprivate class InhertiedPropertyNameConflict : Super
  {
    @Attribute("id")
    var id2 : String
  }


// MARK: -


// MARK: -

final class UniquenessTests : XCTestCase
  {
    func testNameConflict() throws
      {
        do {
          _ = try Schema(name: "", objectTypes: [PropertyNameConflict.self])
          XCTFail("expected error not thrown")
        }
        catch let error {
          print(error)
        }
      }

    func testInheritedNameConflict() throws
      {
        do {
          _ = try Schema(name: "", objectTypes: [InhertiedPropertyNameConflict.self])
          XCTFail("expected error not thrown")
        }
        catch let error {
          print(error)
        }
      }
  }

