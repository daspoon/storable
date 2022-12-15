/*

*/

import CoreData


/// StorableAsData provides an implementation of Storable using NSData as the storage type.
public protocol StorableAsData : Codable, Storable
  { }


extension StorableAsData
  {
    public static var attributeType : NSAttributeDescription.AttributeType
      { .binaryData }

    public func storedValue() throws -> NSData
      { try JSONEncoder().encode(self) as NSData }

    public static func decodeStoredValue(_ data: NSData) throws -> Self
      { try JSONDecoder().decode(Self.self, from: data as Data) }
  }


/// Arrays are StorableAsData when their elements are Codable
extension Array : Storable, StorableAsData where Element : Codable
  { }


/// Dictionaries are StorableAsData when their keys and values are Codable
extension Dictionary : Storable, StorableAsData where Key : Codable, Value : Codable
  { }
