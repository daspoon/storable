/*

  Created by David Spooner

  Extensions to XCTestCase for the convenience of writing test cases.

*/

import XCTest
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

    /// Create and open a store for the given schema and migrations..
    func createAndOpenStoreWith(schema s: Schema, migrations ms: [Migration] = []) throws -> DataStore
      { try createStore{ try $0.openWith(schema: s, migrations: ms) } }

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
        let store = DataStore(name: storeName)
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


    /// Given two schemas, ensure that the version hashes of the implied object models have the expected relationship.
    func checkObjectModelHashes(match expectedMatch: Bool, _ original: Schema, _ modified: Schema) throws
      {
        let versionId = "*"
        let originalModel = try original.createRuntimeInfo(withVersionId: versionId).managedObjectModel
        let modifiedModel = try modified.createRuntimeInfo(withVersionId: versionId).managedObjectModel

        let actualMatch = originalModel.entityVersionHashesByName == modifiedModel.entityVersionHashesByName
        if actualMatch != expectedMatch {
          XCTFail("model hash values are expected to " + (expectedMatch ? "match" : "differ"))
        }
      }
  }
