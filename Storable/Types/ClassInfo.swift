/*

  Created by David Spooner

*/

import CoreData


/// ClassInfo pairs instances of types Entity and NSEntityDescription for a specific subclass of ManagedObject. It exists primarily to enable ingestion of managed objects by providing access to property metadata.

@dynamicMemberLookup
public struct ClassInfo
  {
    public let entityInfo : Entity
    public let entityDescription : NSEntityDescription


    public init(_ entityInfo: Entity, _ entityDescription: NSEntityDescription)
      {
        self.entityInfo = entityInfo
        self.entityDescription = entityDescription
      }


    /// Provide convenient access to the properties of Entity.
    public subscript <Value>(dynamicMember path: KeyPath<Entity, Value>) -> Value
      { entityInfo[keyPath: path] }
  }


extension ClassInfo
  {
    /// Called on ingestion to create an instance of the represented entity from a given JSON value.
    @discardableResult
    func createObject(from jsonValue: Any, in store: DataStore, delay: (@escaping () throws -> Void) -> Void) throws -> ManagedObject
      { try entityInfo.managedObjectClass.init(self, with: .value([:]), in: store, delay: delay) }


    /// Called on ingestion to create a list of instances of the represented entity from a given JSON value.
    @discardableResult
    func createObjects(from jsonValue: Any, with format: IngestFormat, in store: DataStore, delay: (@escaping () throws -> Void) -> Void) throws -> [ManagedObject]
      {
        var objects : [ManagedObject] = []
        switch format {
          case .any :
            objects.append(try entityInfo.managedObjectClass.init(self, with: .value(jsonValue), in: store, delay: delay))
          case .array :
            let jsonArray = try throwingCast(jsonValue, as: [Any].self)
            for (index, value) in jsonArray.enumerated() {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .arrayElement(index: index, value: value), in: store, delay: delay))
            }
          case .dictionary :
            let jsonDict = try throwingCast(jsonValue, as: [String: Any].self)
            for (instanceName, jsonValue) in jsonDict {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: jsonValue), in: store, delay: delay))
            }
          case .dictionaryAsArrayOfKeys :
            let jsonArray = try throwingCast(jsonValue, as: [String].self)
            for instanceName in jsonArray {
              objects.append(try entityInfo.managedObjectClass.init(self, with: .dictionaryEntry(key: instanceName, value: [:]), in: store, delay: delay))
            }
        }
        return objects
      }
  }
