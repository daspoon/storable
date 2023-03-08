/*

  Created by David Spooner

*/

import CoreData


/// ClassInfo pairs instances of types EntityInfo and NSEntityDescription for a specific subclass of Entity. It exists primarily to enable ingestion of managed objects by providing access to property metadata.

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


    /// Provide convenient access to the properties of EntityInfo.
    public subscript <Value>(dynamicMember path: KeyPath<EntityInfo, Value>) -> Value
      { entityInfo[keyPath: path] }
  }


extension ClassInfo
  {
    /// Called on ingestion to create an instance of the represented entity from a given JSON value.
    @discardableResult
    func createObject(from jsonValue: Any, in context: IngestContext) throws -> Entity
      { try entityInfo.managedObjectClass.init(self, with: .value([:]), in: context) }


    /// Called on ingestion to create a list of instances of the represented entity from a given JSON value.
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
          case .dictionaryAsArrayOfKeys :
            let jsonArray = try throwingCast(jsonValue, as: [String].self)
            for instanceName in jsonArray {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: [:]), in: context))
            }
        }
        return objects
      }
  }
