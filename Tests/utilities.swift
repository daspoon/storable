/*

  Created by David Spooner

*/

import CoreData
import Storable
import XCTest


// MARK: --
// For testing convenience, ObjectModelComponent enables common treatment of model component classes which have a version hash.

protocol ObjectModelComponent : NSObject
  { var versionHash : Data { get } }

extension NSEntityDescription : ObjectModelComponent {}
extension NSPropertyDescription : ObjectModelComponent {}


// MARK: --

extension NSAttributeDescription
  {
    convenience init(name: String, type: AttributeType = .string, _ customize: ((NSAttributeDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        self.type = type
        customize?(self)
      }
  }

extension NSFetchedPropertyDescription
  {
    convenience init(name: String, _ customize: ((NSFetchedPropertyDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSRelationshipDescription
  {
    convenience init(name: String, _ customize: ((NSRelationshipDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSEntityDescription
  {
    convenience init(name: String, _ customize: ((NSEntityDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSManagedObjectModel
  {
    convenience init(entities: [NSEntityDescription])
      {
        self.init()
        self.entities = entities
      }
  }


// MARK: --

extension DataStore
  {
    func create<T: Entity>(_ type: T.Type = T.self, initialize f: (T) throws -> Void = {_ in }) throws -> T
      { try managedObjectContext.create(type, initialize: f) }

    public func fetchObjects<T: Entity>(of type: T.Type = T.self, satisfying predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) throws -> [T]
      { try managedObjectContext.fetchObjects(makeFetchRequest(for: type, predicate: predicate, sortDescriptors: sortDescriptors)) }

    public func fetchObject<T: Entity>(of type: T.Type = T.self, satisfying predicate: NSPredicate) throws -> T
      { try managedObjectContext.fetchObject(makeFetchRequest(for: type, predicate: predicate)) }

    func migrate(from sourceEntity: NSEntityDescription, to targetEntity: NSEntityDescription) throws
      {
        let sourceModel = NSManagedObjectModel(entities: [sourceEntity.copy() as! NSEntityDescription])
        let targetModel = NSManagedObjectModel(entities: [targetEntity.copy() as! NSEntityDescription])
        try self.migrate(from: sourceModel, to: targetModel)
      }

    func update(as entity: NSEntityDescription, using script: (NSManagedObjectContext) throws -> Void) throws
      {
        let model = NSManagedObjectModel(entities: [entity.copy() as! NSEntityDescription])
        try self.update(as: model, using: script)
      }
  }


// MARK: --

extension ProcessInfo
  {
    var argumentsByName : [String: String]
      {
        Dictionary(uniqueKeysWithValues: arguments.dropFirst().compactMap { arg in
          let components = arg.components(separatedBy: "=")
          guard components.count == 2 else { return nil }
          return (components[0], components[1])
        })
      }
  }

// MARK: --

fileprivate var activeStores : [String: DataStore] = [:]
fileprivate let activeStoresSemaphore = DispatchSemaphore(value: 1)

extension XCTestCase
  {
    fileprivate func createStore<T: DataStore>(of type: T.Type = T.self, configuration configure: (T) throws -> Void) throws -> T
      {
        activeStoresSemaphore.wait()
        defer {
          activeStoresSemaphore.signal()
        }

        let storeName = "\(Self.self)"
        guard activeStores[storeName] == nil else { throw Exception("store name in use: \(storeName)") }
        let store = T.init(name: storeName)
        activeStores[storeName] = store

        addTeardownBlock {
          activeStores.removeValue(forKey: storeName)
          if store.isOpen { try store.close() }
          try store.reset()
        }

        try store.reset()
        try configure(store)
        return store
      }

    func createAndOpenStoreWith(model m: NSManagedObjectModel) throws -> DataStore
      { try createStore { try $0.openWith(model: m) } }

    func createAndOpenStoreWith(schema s: Schema, migrations ms: [Migration] = []) throws -> DataStore
      { try createStore{ try $0.openWith(schema: s, migrations: ms) } }
  }


// MARK: --
// The current definition of Attribute requires its associated type be Ingestible; make Data and Date conform to enable their use in unit tests.

extension Data : Ingestible
  {
    public init(json: String) throws
      { throw Exception("todo") }
  }

extension Date : Ingestible
  {
    public init(json: String) throws
      { throw Exception("todo") }
  }
