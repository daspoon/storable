/*

*/


/// Conforming types determine how json content translates to a set of object instances.
public protocol DataDefinition
  {
    func ingest(from dataSource: DataSource, into context: IngestContext) throws

    var ingestDescription : String { get }
  }


/// Create a set of instances of a named entity from a specified file.
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
          switch content.format {
            case .any :
              let jsonValue = try dataSource.load(content)
              _ = try entity.managedObjectClass.init(entity, with: .value(jsonValue), in: context)
            case .array :
              let jsonArray = try dataSource.load(content, of: [Any].self)
              for (index, value) in jsonArray.enumerated() {
                _ = try entity.managedObjectClass.init(entity, with: .arrayElement(index: index, value: value), in: context)
              }
            case .dictionary :
              let jsonDict = try dataSource.load(content, of: [String: Any].self)
              for (instanceName, jsonValue) in jsonDict {
                _ = try entity.managedObjectClass.init(entity, with: .dictionaryEntry(key: instanceName, value: jsonValue), in: context)
              }
            case .dictionaryAsArryOfKeys :
              let jsonArray = try dataSource.load(content, of: [String].self)
              for instanceName in jsonArray {
                _ = try entity.managedObjectClass.init(entity, with: .dictionaryEntry(key: instanceName, value: [:]), in: context)
              }
          }
        }
        else {
          _ = try entity.managedObjectClass.init(entity, with: .value([:]), in: context)
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

