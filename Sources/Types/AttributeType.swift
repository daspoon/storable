/*

*/

import CoreData


/// AttributeType identifies types which are supported directly by CoreData attribute storage; this includes Int, String and Data, but also optional wrappings of those types.

// The associated type StorageType enables us to prevent conformance by optional optional types such as Int??.
// The isOptional method is necessary to configure the associated NSAttributeDescription, while nullValue and isNullValue are required to get and set managed values of optional type.

public protocol AttributeType
  {
    /// The underlying storage type.
    associatedtype StorageType : AttributeType

    /// The identifier for the underlying storage type.
    static var typeId : NSAttributeDescription.AttributeType { get }

    /// Indicates whether or not the type is optional. The default implementation returns false.
    static var isOptional : Bool { get }

    /// The null value of the type, assuming the type is optional. The defaut implementation generates a fatal error, so implementations for which isOptional returns true must implement this method to return an appropriate value.
    static var nullValue : Self { get }

    /// Determines whether or not a member value is null. The default implementation returns false.
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


extension URL : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .uri }
  }


extension UUID : AttributeType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .uuid }
  }


// Boxed<Value> is an AttributeType (via ValueTransformer) when its Value is Codable.

extension Boxed : AttributeType where Value : Codable
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .transformable }
  }
