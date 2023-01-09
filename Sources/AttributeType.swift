/*

*/

import CoreData


// AttributeType identifies types which are supported directly by CoreData attribute storage; this includes Int, String and Data, but also optional wrappings of those types.
// The associated type StorageType enables us to prevent conformance by optional optional types such as Int??.
// The isOptional method is necessary to configure the associated NSAttributeDescription, while nullValue and isNullValue are required to get and set managed values of optional type.

public protocol AttributeType
  {
    static var typeId : NSAttributeDescription.AttributeType { get }

    associatedtype StorageType : AttributeType

    static var isOptional : Bool { get }

    static var nullValue : Self { get }

    var isNullValue : Bool { get }
  }


// Using an extension, conformance for non-optional types is reduced to declaring the attribute type.

extension AttributeType
  {
    public typealias StorageType = Self

    public static var isOptional : Bool
      { false }

    public static var nullValue : Self
      { fatalError("required when isOptional returns true") }

    public var isNullValue : Bool
      { false }
  }


extension Bool : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .boolean }
  }


extension Data : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .binaryData }
  }


extension Date : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .date }
  }


extension Double : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .double }
  }


extension Float : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .float }
  }


extension Int : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension Int16 : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer16}
  }


extension Int32 : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer32 }
  }


extension Int64 : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension String : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .string }
  }


// An Optional is an AttributeType when its wrapped type is an AttributeType.

extension Optional : AttributeType where Wrapped : AttributeType, Wrapped.StorageType == Wrapped
  {
    public typealias StorageType = Wrapped

    public static var typeId : NSAttributeDescription.AttributeType
      { Wrapped.typeId }

    public static var isOptional : Bool
      { true }

    public static var nullValue : Self
      { .none }

    public var isNullValue : Bool
      {
        guard case .none = self else { return false }
        return true
      }
  }
