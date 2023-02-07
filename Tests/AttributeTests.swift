/*

 Tests of managed attribute access and update.

*/

import XCTest
@testable import Compendium


// MARK: - a class with the range of standard attributes -

@objc(FullyAttributed)
fileprivate class FullyAttributed : Object
  {
    @Attribute("boolValue")
    var boolValue : Bool

    @Attribute("intValue")
    var intValue : Int

    @Attribute("int16Value")
    var int16Value : Int16

    @Attribute("int32Value")
    var int32Value : Int32

    @Attribute("int64Value")
    var int64Value : Int64

    @Attribute("floatValue")
    var floatValue : Float

    @Attribute("doubleValue")
    var doubleValue : Double

    @Attribute("stringValue")
    var stringValue : String

    @Attribute("dateValue")
    var dateValue : Date

    @Attribute("dataValue")
    var dataValue : Data

    @Attribute("urlValue")
    var urlValue : URL

    @Attribute("uuidValue")
    var uuidValue : UUID

    @Attribute("optionalIntValue")
    var optionalIntValue : Int?
  }


// MARK: - a class with the range of standard attributes and default values -

@objc(DefaultAttributed)
fileprivate class DefaultAttributed : Object
  {
    @Attribute("boolValue")
    var boolValue : Bool = true

    @Attribute("intValue")
    var intValue : Int = 1

    @Attribute("int16Value")
    var int16Value : Int16 = 2

    @Attribute("int32Value")
    var int32Value : Int32 = 3

    @Attribute("int64Value")
    var int64Value : Int64 = 4

    @Attribute("floatValue")
    var floatValue : Float = 5.5

    @Attribute("doubleValue")
    var doubleValue : Double = 6.5

    @Attribute("stringValue")
    var stringValue : String = "heynow"

    @Attribute("dateValue")
    var dateValue : Date = .now

    @Attribute("dataValue")
    var dataValue : Data = .init()

    @Attribute("optionalIntValue")
    var optionalIntValue : Int? = nil
  }


// MARK: - compiler rejection of non-storable types -

#if false
@objc(WronglyAttributed)
fileprivate class WronglyAttributed : Object
  {
    enum MyEnum { case one, two, three }
    struct MyStruct { var intValue : Int }
    class MyObject { }

    @Attribute("myObject")
    var myObject : MyObject

    @Attribute("myEnum")
    var myEnum : MyEnum

    @Attribute("myStruct")
    var myStruct : MyStruct

    @Attribute("myOptional")
    var myOptional : MyStruct?

    @Attribute("optionalOptional")
    var myOptionalOptional : Int??
  }
#endif


// MARK: - unit tests -

final class AttributeTests : XCTestCase
  {
    func testStandard() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [FullyAttributed.self]))

        // Define the attribute values assigned on creation
        let boolValue : Bool = true
        let int16Value : Int16 = 16
        let int32Value : Int32 = 32
        let int64Value : Int64 = 64
        let intValue : Int = 128
        let floatValue : Float = 99.5
        let doubleValue : Double = 999.5
        let stringValue : String = "heynow"
        let dateValue : Date = .now
        let dataValue : Data = "heynow".data(using: .utf8)!
        let urlValue : URL = .init(string: "https://apple.com")!
        let uuidValue : UUID = .init()

        // Create an object instance, assigning the previously defined attribute values
        let object = try store.create(FullyAttributed.self) { object in
          object.boolValue = boolValue
          object.int16Value = int16Value
          object.int32Value = int32Value
          object.int64Value = int64Value
          object.intValue = intValue
          object.floatValue = floatValue
          object.doubleValue = doubleValue
          object.stringValue = stringValue
          object.dateValue = dateValue
          object.dataValue = dataValue
          object.urlValue = urlValue
          object.uuidValue = uuidValue
        }

        try store.save()

        // Ensure attributes have the expected values
        XCTAssertEqual(boolValue, object.boolValue)
        XCTAssertEqual(intValue, object.intValue)
        XCTAssertEqual(int16Value, object.int16Value)
        XCTAssertEqual(int32Value, object.int32Value)
        XCTAssertEqual(int64Value, object.int64Value)
        XCTAssertEqual(floatValue, object.floatValue)
        XCTAssertEqual(doubleValue, object.doubleValue)
        XCTAssertEqual(stringValue, object.stringValue)
        XCTAssertEqual(dateValue, object.dateValue)
        XCTAssertEqual(dataValue, object.dataValue)
        XCTAssertEqual(urlValue, object.urlValue)
        XCTAssertEqual(uuidValue, object.uuidValue)

        // Ensure the optional attribute has value nil
        XCTAssertEqual(object.optionalIntValue, nil)

        // Assign and retrieve values for the optional attribute
        object.optionalIntValue = 42
        XCTAssertEqual(object.optionalIntValue, 42)
        object.optionalIntValue = nil
        XCTAssertEqual(object.optionalIntValue, nil)
      }


    func tesDefaulted() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [FullyAttributed.self]))

        let object = try store.create(DefaultAttributed.self) { _ in }

        print(object.intValue)
      }
  }
