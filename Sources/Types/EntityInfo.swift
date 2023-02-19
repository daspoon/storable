/*

*/

import CoreData


/// EntityInfo is a convenience struct combining ObjectInfo and NSEntityDescription.

@dynamicMemberLookup
public struct EntityInfo
  {
    /// IngestFormat indicates how json data is to be interpreted.
    public enum IngestFormat
      {
        /// An arbitrary value
        case any
        /// An array of arbitrary values
        case array
        /// A dictionary mapping string keys to arbitrary values
        case dictionary
        /// An array of strings interpreted as a dictionary mapping the elements to an empty dictionary (or an arbitrary value?).
        case dictionaryAsArryOfKeys
      }

    public let objectInfo : ObjectInfo
    public let entityDescription : NSEntityDescription

    public init(_ objectInfo: ObjectInfo, _ entityDescription: NSEntityDescription)
      {
        self.objectInfo = objectInfo
        self.entityDescription = entityDescription
      }


    public subscript <Value>(dynamicMember path: KeyPath<ObjectInfo, Value>) -> Value
      { objectInfo[keyPath: path] }


    @discardableResult
    func createObject(from jsonValue: Any, in context: IngestContext) throws -> Object
      { try objectInfo.managedObjectClass.init(self, with: .value([:]), in: context) }


    @discardableResult
    func createObjects(from jsonValue: Any, with format: IngestFormat, in context: IngestContext) throws -> [Object]
      {
        var objects : [Object] = []
        switch format {
          case .any :
            objects.append(try objectInfo.managedObjectClass.init(self, with: .value(jsonValue), in: context))
          case .array :
            let jsonArray = try throwingCast(jsonValue, as: [Any].self)
            for (index, value) in jsonArray.enumerated() {
              objects.append(try objectInfo.managedObjectClass.init(self, with: .arrayElement(index: index, value: value), in: context))
            }
          case .dictionary :
            let jsonDict = try throwingCast(jsonValue, as: [String: Any].self)
            for (instanceName, jsonValue) in jsonDict {
              objects.append(try objectInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: jsonValue), in: context))
            }
          case .dictionaryAsArryOfKeys :
            let jsonArray = try throwingCast(jsonValue, as: [String].self)
            for instanceName in jsonArray {
              objects.append(try objectInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: [:]), in: context))
            }
        }
        return objects
      }


  }
