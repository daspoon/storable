/*

*/


/// Conforming types determine how json content translates to a set of object instances.
public protocol DataDefinition
  {
    func ingest(from dataSource: DataSource, into context: IngestContext) throws
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
        let entity = try context.entity(for: entityName)
        if let content {
          switch content.format {
            case .any :
              let jsonValue = try dataSource.load(content)
              _ = try entity.managedObjectClass.init(entity, with: .init(key: nil, value: jsonValue), in: context)
            case .array :
              let jsonArray = try dataSource.load(content, of: [String].self)
              for instanceName in jsonArray {
                _ = try entity.managedObjectClass.init(entity, with: .init(key: instanceName, value: [:]), in: context)
              }
            case .dictionary :
              let jsonDict = try dataSource.load(content, of: [String: Any].self)
              for (instanceName, jsonValue) in jsonDict {
                _ = try entity.managedObjectClass.init(entity, with: .init(key: instanceName, value: jsonValue), in: context)
              }
          }
        }
        else {
          _ = try entity.managedObjectClass.init(entity, with: .init(key: nil, value: [:]), in: context)
        }
      }
  }


/// Create a set of RaceFusion instances from a file containing a fusion table.
public struct RaceFusionDefinition : DataDefinition
  {
    public let entityName : String
    public let content : DataSource.Content

    public init(entityName x: String, content c: DataSource.Content)
      {
        entityName = x
        content = c
      }

    public func ingest(from dataSource: DataSource, into context: IngestContext) throws
      {
        let entity = try context.entity(for: "RaceFusion")

        let fusion_chart = try dataSource.load(content, of: [String: Any].self)
        let raceNames = try fusion_chart.requiredValue(of: [String].self, for: "races")
        let fusionTable = try fusion_chart.requiredValue(of: [[String]].self, for: "table")
        for i in 0 ..< raceNames.count {
          for j in 0 ..< i {
            guard fusionTable[i][j] != "-" else { continue }
            let ingestData = IngestData(
              key: fusionTable[i][j],
              value: [
                "index": i * raceNames.count + j,
                "inputs": [raceNames[i], raceNames[j]]
              ]
            )
            _ = try entity.managedObjectClass.init(entity, with: ingestData, in: context)
          }
        }
      }
  }