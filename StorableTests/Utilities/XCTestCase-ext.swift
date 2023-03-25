/*

  Created by David Spooner

  Extensions to XCTestCase for the convenience of writing test cases.

*/

import XCTest
import CoreData
import Storable


// Map test class names to DataStore instances.
fileprivate var activeStores : [String: DataStore] = [:]

// Control access to the activeStores dictionary.
fileprivate let activeStoresSemaphore = DispatchSemaphore(value: 1)


extension XCTestCase
  {
    /// Create and open a store for the given object model.
    func createAndOpenStoreWith(model m: NSManagedObjectModel) throws -> DataStore
      { try createStore { try $0.openWith(model: m) } }

    /// Create and open a store for the given schema.
    func createAndOpenStoreWith(schema s: Schema) throws -> DataStore
      { try createStore{ try $0.openWith(schema: s) } }

    /// Create a store with the underlying file named by the receiver's class, adding a teardown block to close and reset its content.
    /// Ensure that each store instance is used by at most one test case.
    fileprivate func createStore(configuration configure: (DataStore) throws -> Void) throws -> DataStore
      {
        activeStoresSemaphore.wait()
        defer {
          activeStoresSemaphore.signal()
        }

        let storeName = "\(Self.self)"
        guard activeStores[storeName] == nil else { throw Exception("store name in use: \(storeName)") }
        let directory = ProcessInfo.processInfo.argument(forKey: "storeDirectory")
        if let directory {
          try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        let store = DataStore(name: storeName, directoryURL: directory.map { URL(filePath: $0) })
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
  }
