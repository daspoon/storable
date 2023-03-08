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

    public var resourceName : String
      { entityType.entityName }

    public func ingest(_ json: Any, into context: IngestContext) throws
      {
        // Get the metadata for the class specified on initialization
        let info = try context.classInfo(for: entityType)

        // Create either a set of instances or a single instance depending on whether or not a resource name is supplied
        switch resourceKeyPath {
          case .none :
            try info.createObject(from: [:], in: context)
          case .some :
            try info.createObjects(from: json, with: ingestFormat, in: context)
        }
      }
  }
