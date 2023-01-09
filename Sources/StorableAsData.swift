/*

*/

import CoreData


/// StorableAsData provides an implementation of Storable using Data as the storage type.
public protocol StorableAsData : Codable, Storable where EncodingType == Data
  { }


extension StorableAsData
  {
    public func storedValue() throws -> Data
      { try JSONEncoder().encode(self) }

    public static func decodeStoredValue(_ data: Data) throws -> Self
      { try JSONDecoder().decode(Self.self, from: data) }
  }


/// Arrays are StorableAsData when their elements are Codable
extension Array : Storable, StorableAsData where Element : Codable
  { }


/// Dictionaries are StorableAsData when their keys and values are Codable
extension Dictionary : Storable, StorableAsData where Key : Codable, Value : Codable
  { }
