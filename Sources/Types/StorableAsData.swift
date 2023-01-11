/*

*/

import CoreData


/// StorableAsData provides an implementation of Storable using Data as the storage type.
public protocol StorableAsData : Storable where Self : Codable, EncodingType == Boxed<Self>
  { }


extension StorableAsData
  {
    public func storedValue() throws -> Boxed<Self>
      { Boxed(value: self) }

    public static func decodeStoredValue(_ boxed: Boxed<Self>) throws -> Self
      { boxed.value }

    public static var valueTransformerName : NSValueTransformerName?
      { .boxedValueTransformerName(for: Self.self) }
  }


/// Arrays are StorableAsData when their elements are Codable
extension Array : Storable, StorableAsData where Element : Codable
  { }


/// Dictionaries are StorableAsData when their keys and values are Codable
extension Dictionary : Storable, StorableAsData where Key : Codable, Value : Codable
  { }
