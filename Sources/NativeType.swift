/*

*/

import CoreData


/// NativeType is used to identity types which are supported directly by CoreData.
public protocol NativeType
  {
    static var attributeType : NSAttributeDescription.AttributeType { get }
  }


extension Bool   : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .boolean } }
extension Int    : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer64 } }
extension Int16  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer16 } }
extension Int32  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer32 } }
extension Int64  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer64 } }
extension Float  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .float } }
extension Double : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .double } }
extension String : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .string } }
