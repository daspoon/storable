/*


*/

import CoreData
import Compendium
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

extension XCTestCase
  {
    /// Create a DataStore instance with a schema for the given object types. Note that the filename of the store, which is derived from the schema, must be unique across instances.
    func dataStore(for types: [Object.Type]) throws -> DataStore
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
