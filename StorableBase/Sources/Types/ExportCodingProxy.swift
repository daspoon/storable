/*

  Created by David Spooner

  TODO: model classes must specify coding container format

*/

import CoreData
import Combine


/// This type is used as a proxy to encode a portion a data store's content.

public struct ExportCodingProxy : Codable
  {
    let dataStore : DataStore
    let managedObjectContext : NSManagedObjectContext
    var rootTypes : [ManagedObject.Type]


    /// Create an instance for the given data store and top-level object types.
    public init(dataStore store: DataStore, managedObjectContext context: NSManagedObjectContext? = nil, rootTypes types: [ManagedObject.Type])
      {
        dataStore = store
        managedObjectContext = context ?? store.managedObjectContext
        rootTypes = types
      }


    // MARK: Decodable

    public init(from decoder: Decoder) throws
      {
        // Get the context from the decoder's userInfo
        guard let decodingContext = decoder.userInfo[ImportContext.codingUserInfoKey] as? ImportContext
          else { throw Exception("decoder's userInfo must contain a ImportContext instance for key ImportContext.codingUserInfoKey") }

        dataStore = decodingContext.dataStore
        managedObjectContext = decodingContext.managedObjectContext
        rootTypes = []

        let topLevelContainer = try decoder.container(keyedBy: NameCodingKey.self)

        // TODO: Ensure the version is compatible...

        let specialKeys = ["_version"]
        for key in topLevelContainer.allKeys {
          guard specialKeys.contains(key.name) == false
            else { continue }
          guard let rootInfo = decodingContext.dataStore.classInfoByName[key.name]
            else { log("ignoring unexpected key: \(key.name)"); continue }

          decodingContext.pushAllocatingEntity(rootInfo)
//        switch rootType.codingContainerFormat {
//          case .array :
              var subcontainer = try topLevelContainer.nestedUnkeyedContainer(forKey: .init(name: rootInfo.objectType.entityName))
              while subcontainer.isAtEnd == false {
                let object = try subcontainer.decode(rootInfo.objectType)
                decodingContext.callback?(object)
              }
//          case .dictionary(let codingNameKeyPath) :
//            var subcontainer = try topLevelContainer.nestedContainer(keyedBy: NameCodingKey.self, forKey: .init(name: rootType.entityName))
//            for key in subcontainer.allKeys {
//              _ = try subcontainer.decode(rootType.self, forKey: key)
//            }
//        }
          decodingContext.popAllocatingEntity()

          rootTypes += [rootInfo.objectType]
        }
      }


    // MARK: Encodable

    public func encode(to encoder: Encoder) throws
      {
        var topLevelContainer = encoder.container(keyedBy: NameCodingKey.self)

        // Encode the schema version...
        try topLevelContainer.encode("0.1", forKey: NameCodingKey(name: "_version"))

        // Fetch and encode the instances of each root type
        for rootType in rootTypes {
          // Retrieve the model objects // TODO: using a batched request
          let rootObjects = try managedObjectContext.fetchObjects(fetchRequest(for: rootType/*, fetchBatchSize: 20*/))
          // Create a nested container as specified by the type
//        switch rootType.codingContainerFormat {
//          case .array :
              var subcontainer = topLevelContainer.nestedUnkeyedContainer(forKey: .init(name: rootType.entityName))
              for object in rootObjects {
                try subcontainer.encode(object)
              }
//          case .dictionary(let codingNameKeyPath) :
//            var subcontainer = topLevelContainer.nestedContainer(keyedBy: NameCodingKey.self, forKey: .init(name: rootType.entityName))
//            for object in rootObjects {
//              subcontainer.encode(object, forKey: NameCodingKey(name: object[keyPath: codingNameKeyPath]))
//            }
//        }
        }
      }
  }

