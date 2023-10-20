/*

  Created by David Spooner

*/

import CoreData


/// AttributeType identifies types which are supported directly by CoreData attribute storage.

public protocol StorageType : Codable
  {
    /// The identifier for the underlying storage type.
    static var typeId : NSAttributeDescription.AttributeType { get }
  }


// Using an extension, conformance for non-optional types is reduced to declaring the attribute type.

extension Bool : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .boolean }
  }


extension Data : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .binaryData }
  }


extension Date : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .date }
  }


extension Double : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .double }
  }


extension Float : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .float }
  }


extension Int : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension Int16 : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer16}
  }


extension Int32 : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer32 }
  }


extension Int64 : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .integer64 }
  }


extension String : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .string }
  }


extension URL : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .uri }
  }


extension UUID : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .uuid }
  }


// Boxed<Value> is an StorageType (via ValueTransformer) when its Value is Codable.

extension Boxed : StorageType where Value : Codable
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .transformable }
  }
