/*

  Created by David Spooner

*/

import CoreData


/// *EditingContext* is a convenience class intended to simplify editing of a managed object graph, providing a child context to maintain editing changes along with a list of actions to be perform on either save or rollback.
/// The created child context is associated with the main queue in order to serve UI elements.

public final class EditingContext
  {
    public struct CallbackTrigger : OptionSet
      {
        public let rawValue : Int
        public init(rawValue v: Int) { rawValue = v }
        public static let save = CallbackTrigger(rawValue: 1)
        public static let cancel = CallbackTrigger(rawValue: 2)
        public static let completion = CallbackTrigger(rawValue: 3)
      }

    /// The parent data store provided on initialization.
    public let dataStore : DataStore

    /// The child context created on initialization.
    public let childContext : NSManagedObjectContext

    /// The actions to be performed on either save or cancel.
    private var actions : [(message: String, trigger: CallbackTrigger, effect: () throws -> Void)] = []

    /// The mapping of URIs to managed object identifiers for temporary objects restored on decoding.
    private var temporaryObjectsByURL : [URL: ManagedObject] = [:]


    /// Create a new editing context on the given parent context.
    public init(name: String? = nil, dataStore store: DataStore)
      {
        dataStore = store
        childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.name = name
        childContext.parent = dataStore.managedObjectContext
        childContext.automaticallyMergesChangesFromParent = true
        childContext.editingContext = self
      }


    deinit
      {
        childContext.editingContext = nil
      }


    /// Enqueue an action to be performed on save, cancel or both.
    public func addAction(_ message: String, on trigger: CallbackTrigger, effect: @escaping () throws -> Void)
      {
        actions.append((message: message, trigger: trigger, effect: effect))
      }


    /// Return a closure to perform the editing actions for a given trigger, enabling execution in a context independent of this object.
    private func actionExecutionClosure(for trigger: CallbackTrigger) -> (() -> Void)
      {
        let actions = self.actions
        return {
          for action in actions {
            guard action.trigger.contains(trigger) else { continue }
            do {
              try action.effect()
              log(action.message)
            }
            catch {
              log("failed to perform '\(action.message)': \(error)")
            }
          }
        }
      }


    /// Return the error which would occur on saving the associated child context. A return or *nil* indicates the child context is free of validation errors and can safely be saved.
    public var validationError : NSError?
      { childContext.validationError }


    /// Save the changes in the local context to the persistent store, invoking the given block on either completion or failure. It is expected that *validationError* is *nil* on calling this method.
    public func save(onCompletion completion: ((Error?) -> Void)? = nil)
      {
        if let validationError {
          preconditionFailure("validation failed: \(validationError)")
        }

        let performActions = actionExecutionClosure(for: .save)
        childContext.performSave { error in
          if error == nil {
            performActions()
          }
          completion?(error)
        }

        temporaryObjectsByURL = [:]
        actions = []
      }


    /// Discard the changes to the local context.
    public func cancel()
      {
        let performActions = actionExecutionClosure(for: .cancel)
        performActions()

        childContext.rollback()

        temporaryObjectsByURL = [:]
        actions = []
      }


    /// Discard the registered objects of the local context.
    public func reset()
      {
        childContext.reset()
      }


    public func existingObject<T: ManagedObject>(of _: T.Type = T.self, with url: URL) -> T?
      {
        let object : NSManagedObject
        switch temporaryObjectsByURL[url] {
          case .some(let restoredObject) :
            log("resolved \(url) to \(restoredObject.objectID.uriRepresentation())")
            object = restoredObject
          case .none :
            guard let id = dataStore.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
              else { log(level: .error, "failed to resolve object URI: \(url)"); return nil }
            guard let obj = try? childContext.existingObject(with: id)
              else { log(level: .error, "failed to resolve object ID: \(id)"); return nil }
            object = obj
        }

        guard let expected = object as? T
          else { log(level: .error, "unexpected resolved object \(type(of: object)) for id \(url)"); return nil }

        return expected
      }


    // State restoration

    struct RestorationState
      {
        static let editingContextCodingKey = CodingUserInfoKey(rawValue: "xyz.lambdasoftware.Storable.EditingContext")!
        init() { }
      }

    /// Return data encoding the changes to the receiver's child context.
    public func encodeRestorationState() throws -> Data
      {
        let coder = JSONEncoder()
        coder.userInfo = [RestorationState.editingContextCodingKey: self]
        return try coder.encode(RestorationState())
      }


    /// Apply the changes encoded in the given data to the receiver's child context.
    public func decodeRestorationState(from data: Data) throws
      {
        let coder = JSONDecoder()
        coder.userInfo = [RestorationState.editingContextCodingKey: self]
        _ = try coder.decode(RestorationState.self, from: data)
      }
  }


extension EditingContext.RestorationState : Codable
  {
    enum CodingKey : String, Swift.CodingKey
      { case name, inserts, updates, deletes }

    init(from coder: Decoder) throws
      {
        guard let editingContext = coder.userInfo[Self.editingContextCodingKey] as? EditingContext
          else { throw Exception("no editing context") }

        guard editingContext.childContext.hasChanges == false
          else { throw Exception("editing context has changes") }

        let container = try coder.container(keyedBy: CodingKey.self)

        // Restore the name of the child context
        editingContext.childContext.name = try container.decodeIfPresent(String.self, forKey: .name)

        // Get the URLs of the inserted objects and create a mapping of those URLs to new object instances.
        let insertedURLs = try container.decode([URL].self, forKey: .inserts)
         editingContext.temporaryObjectsByURL = try Dictionary(uniqueKeysWithValues: insertedURLs.map { url in
          guard let entityName = url.coreDataEntityName
            else { throw Exception("failed to interpret URL: \(url)") }
          let classInfo = try editingContext.dataStore.classInfo(for: entityName)
          let object = classInfo.managedObjectClass.init(entity: classInfo.entityDescription, insertInto: editingContext.childContext)
          log("created replacement \(object.objectID.uriRepresentation()) for \(url)")
          return (url, object)
        })

        // Define a function to retrieve objects by URL, whether temporary or permanent
        func objectByURL(_ url: URL) throws -> ManagedObject {
          switch url.coreDataResidenceType {
            case .some(.permanent) :
              guard let id = editingContext.dataStore.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
                else { throw Exception("uknown object URI: \(url)") }
              guard let object = try editingContext.childContext.existingObject(with: id) as? ManagedObject
                else { throw Exception("failed to retrieve existing object for URI: \(url)") }
              return object
            case .some(.temporary) :
              guard let object = editingContext.temporaryObjectsByURL[url]
                else { throw Exception("failed to retrieve new object for URI: \(url)") }
              return object
            case .none :
              throw Exception("unexpected object URI: \(url)")
          }
        }

        // From the keyed container in which object updates are encoded, apply the property changes stored in a subcontainer to the object identified by each key.
        let objectUpdatesByURL = try container.nestedContainer(keyedBy: URLCodingKey.self, forKey: .updates)
        for key in objectUpdatesByURL.allKeys {
          let object = try objectByURL(key.url)
          let classInfo = try editingContext.dataStore.classInfo(for: object)
          var propertyUpdatesContainer = try objectUpdatesByURL.nestedContainer(keyedBy: NameCodingKey.self, forKey: key)
          try object.decodeProperties(classInfo.allPropertiesByName, from: &propertyUpdatesContainer, objectByURL: objectByURL)
        }

        // Delete the specified objects.
        let deletedURLs = try container.decode([URL].self, forKey: .deletes)
        for url in deletedURLs {
          guard let objectID = editingContext.dataStore.persistentStoreCoordinator.managedObjectID(forURIRepresentation: url)
            else { throw Exception("uknown object URI: \(url)") }
          log("deleting \(url)")
          editingContext.childContext.delete(try editingContext.childContext.existingObject(with: objectID))
        }
      }


    func encode(to coder: Encoder) throws
      {
        guard let editingContext = coder.userInfo[Self.editingContextCodingKey] as? EditingContext
          else { throw Exception("no editing context") }

        var container = coder.container(keyedBy: CodingKey.self)

        // Encode the context name, if any
        try editingContext.childContext.name.map { try container.encode($0, forKey: .name) }

        // Encode an array the inserted object URLs.
        try container.encode(editingContext.childContext.insertedObjects.map { $0.objectID.uriRepresentation() }, forKey: .inserts)

        // Encode the updated objects in a keyed container mapping object URI to a separate container encoding property value changes.
        var objectUpdatesByURL = container.nestedContainer(keyedBy: URLCodingKey.self, forKey: .updates)
        for objects in [editingContext.childContext.insertedObjects, editingContext.childContext.updatedObjects] {
          for object in objects {
            guard let object = object as? ManagedObject
              else { throw Exception("unsupported object type: \(type(of: object))") }
            let key = URLCodingKey(url: object.objectID.uriRepresentation())
            var propertyUpdatesContainer = objectUpdatesByURL.nestedContainer(keyedBy: NameCodingKey.self, forKey: key)
            let classInfo = try editingContext.dataStore.classInfo(for: object)
            log("saving changes to \(key.url)")
            try object.encodeProperties(classInfo.allPropertiesByName, to: &propertyUpdatesContainer)
          }
        }

        // Encode an array the deleted object URLs.
        try container.encode(editingContext.childContext.deletedObjects.map { $0.objectID.uriRepresentation() }, forKey: .deletes)
      }
  }
