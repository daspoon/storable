/*

*/


/// The DataDefinition protocol is used to enable object ingestion from a variety of data formats.

public protocol DataDefinition
  {
    /// Taking the required data from the given source, create the defined objects in the given context.
    func ingest(from dataSource: DataSource, into context: IngestContext) throws

    /// Describe the data being ingested, for logging purposes.
    var ingestDescription : String { get }
  }


/// EntitySetDefinition is used to create a set of instances of a named entity from the specified content.

public struct EntitySetDefinition : DataDefinition
  {
    public let entityName : String
    public let content : DataSource.Content?

    public init(entityName x: String, content c: DataSource.Content? = nil)
      {
        entityName = x
        content = c
      }

    public func ingest(from dataSource: DataSource, into context: IngestContext) throws
      {
        let entity = try context.entityInfo(for: entityName)
        if let content {
          let json = try dataSource.load(content)
          try entity.createObjects(from: json, with: content.format, in: context)
        }
        else {
          try entity.createObject(from: [:], in: context)
        }
      }

    public var ingestDescription : String
      {
        switch content {
          case .some(let content) : return "ingesting \(entityName) from \(content.resourceNameAndKeyPath) as \(content.format)"
          case .none : return "creating \(entityName)"
        }
      }
  }

