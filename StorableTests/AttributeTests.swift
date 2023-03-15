/*

  Created by David Spooner

  Tests of assignment and retrieval of supported attribute types.

*/

import XCTest
import Storable


// Define types and values for convenience in subsequent test cases:

// a Codable type,
fileprivate struct Point : Equatable, StorableAsData { var x, y: Float }

// a RawRepresentable type,
fileprivate enum Level : Int, Storable { case low, medium, high }

// and some attribute values...
fileprivate let boolValue : Bool = true
fileprivate let int16Value : Int16 = 16
fileprivate let int32Value : Int32 = 32
fileprivate let int64Value : Int64 = 64
fileprivate let intValue : Int = 128
fileprivate let floatValue : Float = 99.5
fileprivate let doubleValue : Double = 999.5
fileprivate let stringValue : String = "heynow"
fileprivate let dateValue : Date = .now
fileprivate let dataValue : Data = "heynow".data(using: .utf8)!
fileprivate let urlValue : URL = .init(string: "https://apple.com")!
fileprivate let uuidValue : UUID = .init()
fileprivate let pointValue : Point = .init(x: 1, y: 2)
fileprivate let levelValue : Level = .medium


final class AttributeTests : XCTestCase
  {
    /// Test assignment and retrieval of non-optional attributes
    func testNonOptional() throws
      {
        // Define an entity with the range of supported attribute types

        @Entity class Object : Entity {
          @Attribute var bool : Bool
          @Attribute var int : Int
          @Attribute var int16 : Int16
          @Attribute var int32 : Int32
          @Attribute var int64 : Int64
          @Attribute var float : Float
          @Attribute var double : Double
          @Attribute var string : String
          @Attribute var date : Date
          @Attribute var data : Data
          @Attribute var url : URL
          @Attribute var uuid : UUID
          @Attribute var point : Point
          @Attribute var level : Level
        }

        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Object.self]))

        // Create an object instance without assigning any attribute values
        let object = try store.create(Object.self)

        // Attempting to save the new object will fail
        do {
          try store.save()
          XCTFail("failed to detect error on saving invalid object")
        }
        catch { }

        // Assign attribute values and save
        object.bool = boolValue
        object.int16 = int16Value
        object.int32 = int32Value
        object.int64 = int64Value
        object.int = intValue
        object.float = floatValue
        object.double = doubleValue
        object.string = stringValue
        object.date = dateValue
        object.data = dataValue
        object.url = urlValue
        object.uuid = uuidValue
        object.point = pointValue
        object.level = levelValue
        try store.save()

        // Ensure attributes have the expected values
        if object.bool != boolValue { XCTFail("") }
        if object.int != intValue { XCTFail("") }
        if object.int16 != int16Value { XCTFail("") }
        if object.int32 != int32Value { XCTFail("") }
        if object.int64 != int64Value { XCTFail("") }
        if object.float != floatValue { XCTFail("") }
        if object.double != doubleValue { XCTFail("") }
        if object.string != stringValue { XCTFail("") }
        if object.date != dateValue { XCTFail("") }
        if object.data != dataValue { XCTFail("") }
        if object.url != urlValue { XCTFail("") }
        if object.uuid != uuidValue { XCTFail("") }
        if object.point != pointValue { XCTFail("") }
        if object.level != levelValue { XCTFail("") }
      }


    /// Test retrieval of non-optional attributes with default values
    func testNonOptionalDefaults() throws
      {
        // Define an entity with the range of supported attribute types, with assigned default values

        @Entity class Object : Entity {
          @Attribute var bool : Bool = boolValue
          @Attribute var int : Int = intValue
          @Attribute var int16 : Int16 = int16Value
          @Attribute var int32 : Int32 = int32Value
          @Attribute var int64 : Int64 = int64Value
          @Attribute var float : Float = floatValue
          @Attribute var double : Double = doubleValue
          @Attribute var string : String = stringValue
          @Attribute var date : Date = dateValue
          @Attribute var data : Data = dataValue
          @Attribute var url : URL = urlValue
          @Attribute var uuid : UUID = uuidValue
          @Attribute var point : Point = pointValue
          @Attribute var level : Level = levelValue
        }

        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Object.self]))

        // Create an object instance without assigning any attribute values
        let object = try store.create(Object.self)

        // Saving is successful because all attributes have default values
        try store.save()

        // Ensure attributes have the expected values
        XCTAssertEqual(object.bool, boolValue)
        XCTAssertEqual(object.int, intValue)
        XCTAssertEqual(object.int16, int16Value)
        XCTAssertEqual(object.int32, int32Value)
        XCTAssertEqual(object.int64, int64Value)
        XCTAssertEqual(object.float, floatValue)
        XCTAssertEqual(object.double, doubleValue)
        XCTAssertEqual(object.string, stringValue)
        XCTAssertEqual(object.date, dateValue)
        XCTAssertEqual(object.data, dataValue)
        XCTAssertEqual(object.url, urlValue)
        XCTAssertEqual(object.uuid, uuidValue)
        XCTAssertEqual(object.point, pointValue)
        XCTAssertEqual(object.level, levelValue)
      }


    func testOptional() throws
      {
        // Define an entity with the range of optional attribute types
        @Entity class Object : Entity {
          @Attribute var bool : Bool?
          @Attribute var int : Int?
          @Attribute var int16 : Int16?
          @Attribute var int32 : Int32?
          @Attribute var int64 : Int64?
          @Attribute var float : Float?
          @Attribute var double : Double?
          @Attribute var string : String?
          @Attribute var date : Date?
          @Attribute var data : Data?
          @Attribute var url : URL?
          @Attribute var uuid : UUID?
          @Attribute var point : Point?
          @Attribute var level : Level?
        }

        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Object.self]))

        // Create an object instance without assigning any attribute values
        let object = try store.create(Object.self)

        // Saving is successful because all attributes are optional
        try store.save()

        // Assign attribute values and save
        object.bool = boolValue
        object.int16 = int16Value
        object.int32 = int32Value
        object.int64 = int64Value
        object.int = intValue
        object.float = floatValue
        object.double = doubleValue
        object.string = stringValue
        object.date = dateValue
        object.data = dataValue
        object.url = urlValue
        object.uuid = uuidValue
        object.point = pointValue
        object.level = levelValue
        try store.save()

        // Ensure attributes have the expected values
        XCTAssertEqual(object.bool, boolValue)
        XCTAssertEqual(object.int, intValue)
        XCTAssertEqual(object.int16, int16Value)
        XCTAssertEqual(object.int32, int32Value)
        XCTAssertEqual(object.int64, int64Value)
        XCTAssertEqual(object.float, floatValue)
        XCTAssertEqual(object.double, doubleValue)
        XCTAssertEqual(object.string, stringValue)
        XCTAssertEqual(object.date, dateValue)
        XCTAssertEqual(object.data, dataValue)
        XCTAssertEqual(object.url, urlValue)
        XCTAssertEqual(object.uuid, uuidValue)
        XCTAssertEqual(object.point, pointValue)
        XCTAssertEqual(object.level, levelValue)

        // Nullify attribute values and save
        object.bool = nil
        object.int16 = nil
        object.int32 = nil
        object.int64 = nil
        object.int = nil
        object.float = nil
        object.double = nil
        object.string = nil
        object.date = nil
        object.data = nil
        object.url = nil
        object.uuid = nil
        object.point = nil
        object.level = nil
        try store.save()
      }
  }
