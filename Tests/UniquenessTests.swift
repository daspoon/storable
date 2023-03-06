/*

  Created by David Spooner

  Ensure the underlying names specified by property wrappers are distinct within the generated entity (accounting for inheritance).

*/

import XCTest
@testable import Storable


// MARK: -

@objc(PropertyNameConflict)
fileprivate class PropertyNameConflict : Entity
  {
    @Attribute("name")
    var firstName : String

    @Attribute("name")
    var lastName : String
  }


// MARK: -

@objc(Super)
fileprivate class Super : Entity
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
          _ = try Schema(objectTypes: [PropertyNameConflict.self])
          XCTFail("expected error not thrown")
        }
        catch let error {
          print(error)
        }
      }

    func testInheritedNameConflict() throws
      {
        do {
          _ = try Schema(objectTypes: [InhertiedPropertyNameConflict.self])
          XCTFail("expected error not thrown")
        }
        catch let error {
          print(error)
        }
      }
  }

