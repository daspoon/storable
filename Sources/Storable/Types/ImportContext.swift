/*

  Created by David Spooner

*/

import CoreData


/// This class provides object creation facilities for use in *ManagedObject*'s implementation of *Decodable*.

class ImportContext
  {
    /// The key with which an instance of this class is regstered in a decoder's *userInfo*.
    static let codingUserInfoKey = CodingUserInfoKey(rawValue: "xyz.lambdasoftware.Storable.ImportContext.codingUserInfoKey")!

    let dataStore : DataStore
    let managedObjectContext : NSManagedObjectContext
    let persistentStoreCoordinator : NSPersistentStoreCoordinator
    let temporaryObjectsByURL : [URL: ManagedObject]
    let callback : ((ManagedObject) -> Void)?

    private var pendingRelationshipAssignments : [(source: ManagedObject, relationship: Relationship, relatedURI: URL)] = []

    private var createdObjectsByURL : [URL: ManagedObject] = [:]


    /// Create a new instance for the given data store. The *managedObjectContext* specifies the context in which objects are created; it defaults to the main context of the data store.
    init(dataStore: DataStore, managedObjectContext: NSManagedObjectContext? = nil, callback: ((ManagedObject) -> Void)? = nil, temporaryObjectsByURL: [URL: ManagedObject] = [:]) throws
      {
        guard let persistentStoreCoordinator = dataStore.persistentStoreCoordinator
          else { throw Exception("dataStore has no persistentStoreCoordinator") }

        self.dataStore = dataStore
        self.managedObjectContext = managedObjectContext ?? dataStore.managedObjectContext
        self.persistentStoreCoordinator = persistentStoreCoordinator
        self.temporaryObjectsByURL = temporaryObjectsByURL
        self.callback = callback
      }


    private var decodingState : [ClassInfo] = []

    var allocatingEntity : ClassInfo?
      { decodingState.last }

    func pushAllocatingEntity(_ entity: ClassInfo)
      { decodingState.append(entity) }

    func popAllocatingEntity()
      { assert(decodingState.isEmpty == false); decodingState.removeLast() }


    /// Schedule addition of the object with the given URL to the specified relationship of the given object. This is useful when decoding relationships whose related objects have not yet been decoded.
    func delayedAddObject(with url: URL, to relationship: Relationship, of object: ManagedObject)
      {
        pendingRelationshipAssignments += [(object, relationship, url)]
      }


    /// Called on completion of decoding to perform all deferred related object assignments.
    func resolvePendingRelationshipAssignments() throws
      {
        for (source, relationship, relatedURI) in pendingRelationshipAssignments {
          do {
            let relatedObject = try objectByURL(relatedURI)
            switch relationship.range {
              case .toOptional, .toOne :
                source.setValue(relatedObject, forKey: relationship.name)
              default :
                source.mutableSetValue(forKey: relationship.name).add(relatedObject)
            }
          }
          catch {
            throw Exception("failed to resolve relationship \(type(of: source)).\(relationship.name): \(error.localizedDescription)")
          }
        }
      }


    func registerCreatedObject(_ object: ManagedObject, forURI url: URL)
      {
        assert(createdObjectsByURL[url] == nil)
        createdObjectsByURL[url] = object
      }


    private func objectByURL(_ url: URL) throws -> ManagedObject {
      switch url.coreDataResidenceType {
        case .some(.permanent) :
          if let object = createdObjectsByURL[url] {
            return object
          }
          guard let id = persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
            else { throw Exception("uknown object URI: \(url)") }
          guard let object = try managedObjectContext.existingObject(with: id) as? ManagedObject
            else { throw Exception("failed to retrieve existing object for URI: \(url)") }
          return object
        case .some(.temporary) :
          guard let object = temporaryObjectsByURL[url]
            else { throw Exception("failed to retrieve new object for URI: \(url)") }
          return object
        case .none :
          throw Exception("unexpected object URI: \(url)")
      }
    }
  }
