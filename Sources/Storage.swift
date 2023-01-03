/*

*/

import CoreData


/// Indicates a type supported directly by CoreData
public protocol Storage
  { }


extension NSData : Storage {}
extension NSDate : Storage {}
extension NSNumber : Storage {}
extension NSString : Storage {}


extension Bool : Storage {}
extension Data : Storage {}
extension Date : Storage {}
extension Double : Storage {}
extension Float : Storage {}
extension Int : Storage {}
extension Int16 : Storage {}
extension Int32 : Storage {}
extension Int64 : Storage {}
extension String : Storage {}


extension Optional : Storage where Wrapped : Storage {}
