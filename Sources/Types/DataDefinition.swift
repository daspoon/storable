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
        let info = try context.classInfo(for: entityName)
        if let content {
          switch content.format {
            case .any :
              let jsonValue = try dataSource.load(content)
              _ = try info.managedObjectClass.init(info, with: .value(jsonValue), in: context)
            case .array :
              let jsonArray = try dataSource.load(content, of: [Any].self)
              for (index, value) in jsonArray.enumerated() {
                _ = try info.managedObjectClass.init(info, with: .arrayElement(index: index, value: value), in: context)
              }
            case .dictionary :
              let jsonDict = try dataSource.load(content, of: [String: Any].self)
              for (instanceName, jsonValue) in jsonDict {
                _ = try info.managedObjectClass.init(info, with: .dictionaryEntry(key: instanceName, value: jsonValue), in: context)
              }
            case .dictionaryAsArryOfKeys :
              let jsonArray = try dataSource.load(content, of: [String].self)
              for instanceName in jsonArray {
                _ = try info.managedObjectClass.init(info, with: .dictionaryEntry(key: instanceName, value: [:]), in: context)
              }
          }
        }
        else {
          _ = try info.managedObjectClass.init(info, with: .value([:]), in: context)
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

