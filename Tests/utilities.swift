/*


*/

import Foundation
import Compendium
import XCTest


// MARK: --

extension XCTestCase
  {
    /// Create a DataStore instance with a schema for the given object types. Note that the filename of the store, which is derived from the schema, must be unique across instances.
    func dataStore(for types: [ManagedObject.Type]) throws -> DataStore
      {
        let name = UUID().uuidString
        let schema = try Schema(name: name, objectTypes: types)
        return try DataStore(schema: schema, reset: true)
      }
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
