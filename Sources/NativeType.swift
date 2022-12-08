/*

*/

import CoreData


/// NativeType is used to identity types which are supported directly by CoreData.
public protocol NativeType
  {
    static var attributeType : NSAttributeDescription.AttributeType { get }

    var asNSObject : NSObject { get }
  }


extension Bool   : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .boolean }  ; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Int    : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer64 }; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Int16  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer16 }; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Int32  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer32 }; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Int64  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .integer64 }; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Float  : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .float }    ; public var asNSObject : NSObject { NSNumber(value: self) } }
extension Double : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .double }   ; public var asNSObject : NSObject { NSNumber(value: self) } }
extension String : NativeType { public static var attributeType : NSAttributeDescription.AttributeType { .string }   ; public var asNSObject : NSObject { self as NSString } }
