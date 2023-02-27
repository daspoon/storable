/*

*/

import CoreData


/// AttributeType identifies types which are supported directly by CoreData attribute storage.

public protocol AttributeType
  {
    /// The identifier for the underlying storage type.
    static var typeId : NSAttributeDescription.AttributeType { get }
  }


// Using an extension, conformance for non-optional types is reduced to declaring the attribute type.

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
