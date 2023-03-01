/*

*/

import CoreData


/// ClassInfo combines an EntityInfo with an NSEntityDescription.
@dynamicMemberLookup
public struct ClassInfo
  {
    public let entityInfo : EntityInfo
    public let entityDescription : NSEntityDescription


    public init(_ entityInfo: EntityInfo, _ entityDescription: NSEntityDescription)
      {
        self.entityInfo = entityInfo
        self.entityDescription = entityDescription
      }


    public subscript <Value>(dynamicMember path: KeyPath<EntityInfo, Value>) -> Value
      { entityInfo[keyPath: path] }
  }


extension ClassInfo
  {
    /// IngestFormat determines how to interpret the json data provided on object ingestion.
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


    @discardableResult
    func createObject(from jsonValue: Any, in context: IngestContext) throws -> Entity
      { try entityInfo.managedObjectClass.init(self, with: .value([:]), in: context) }


    @discardableResult
    func createObjects(from jsonValue: Any, with format: IngestFormat, in context: IngestContext) throws -> [Entity]
      {
        var objects : [Entity] = []
        switch format {
          case .any :
            objects.append(try entityInfo.managedObjectClass.init(self, with: .value(jsonValue), in: context))
          case .array :
            let jsonArray = try throwingCast(jsonValue, as: [Any].self)
            for (index, value) in jsonArray.enumerated() {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .arrayElement(index: index, value: value), in: context))
            }
          case .dictionary :
            let jsonDict = try throwingCast(jsonValue, as: [String: Any].self)
            for (instanceName, jsonValue) in jsonDict {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: jsonValue), in: context))
            }
          case .dictionaryAsArryOfKeys :
            let jsonArray = try throwingCast(jsonValue, as: [String].self)
            for instanceName in jsonArray {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: [:]), in: context))
            }
        }
        return objects
      }
  }
