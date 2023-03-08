/*

  Created by David Spooner

*/


/// EntityIngestMethod is used to create a set of instances of an associated Entity subclass from a specified resource.

public struct EntityIngestMethod : IngestMethod
  {
    public let entityType : Entity.Type
    public let resourceKeyPath : String?
    public let ingestFormat : IngestFormat

    public init<T: Entity>(type: T.Type = T.self, keyPath: String? = nil, format: IngestFormat = .dictionary)
      {
        entityType = type
        resourceKeyPath = keyPath
        ingestFormat = format
      }

    public var methodIdentifier : String
      { entityType.entityName }

    public func ingest(_ json: Any, into store: DataStore, delay: (@escaping () throws -> Void) -> Void) throws
      {
        // Get the metadata for the class specified on initialization
        let info = try store.classInfo(for: entityType.entityName)

        // Create either a set of instances or a single instance depending on whether or not a resource name is supplied
        switch resourceKeyPath {
          case .none :
            try info.createObject(from: [:], in: store, delay: delay)
          case .some :
            try info.createObjects(from: json, with: ingestFormat, in: store, delay: delay)
        }
      }
  }
