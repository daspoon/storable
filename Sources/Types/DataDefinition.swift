/*

  Created by David Spooner

*/


/// The DataDefinition protocol is used to enable object ingestion from a variety of data formats.

public protocol DataDefinition
  {
    /// The name of the resource for logging purposes.
    var resourceName : String { get }

    /// A dot-separated key path identifying the required JSON data as a component of a bundle resource; the first path element specifies the name of the bundle resource, and subsequent elements are treated as dictionary keys (meaning the bundle resource is a dictionary). Returning nil indicates the definition requires no data and thus the first argument of ingest(:into:) is arbitrary.
    var resourceKeyPath : String? { get }

    /// Create objects from the JSON resource data.
    func ingest(_ json: Any, into context: IngestContext) throws
  }


/// EntitySetDefinition is used to create a set of instances of a named entity from the specified content.

public struct EntitySetDefinition : DataDefinition
  {
    public let entityType : Entity.Type
    public let resourceKeyPath : String?
    public let ingestFormat : ClassInfo.IngestFormat

    public init<T: Entity>(type: T.Type = T.self, keyPath: String? = nil, format: ClassInfo.IngestFormat = .dictionary)
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
