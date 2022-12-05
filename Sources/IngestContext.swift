/*

*/

import CoreData


public class IngestContext
  {
    let objectInfo : [String: ObjectInfo]
    let managedObjectContext : NSManagedObjectContext

    private var ingesting : Bool = false
    private var delayedEffects : [() throws -> Void] = []


    static func populate(managedObjectContext moc: NSManagedObjectContext, objectInfo: [String: ObjectInfo], dataSource: DataSource) throws
      {
        let context = try IngestContext(managedObjectContext: moc, objectInfo: objectInfo)

        context.beginIngestion()

        // Ingest each defined type
        for definition in dataSource.definitions {
          switch definition {
            case .entitySet(let entityName, let content) :
              let info = try context.objectInfo(for: entityName)
              if let content {
                switch content.format {
                  case .any :
                    let jsonValue = try dataSource.load(content)
                    _ = try info.managedObjectClass.init(info.entityDescription, with: .init(key: nil, value: jsonValue), in: context)
                  case .array :
                    let jsonArray = try dataSource.load(content, of: [String].self)
                    for instanceName in jsonArray {
                      _ = try info.managedObjectClass.init(info.entityDescription, with: .init(key: instanceName, value: [:]), in: context)
                    }
                  case .dictionary :
                    let jsonDict = try dataSource.load(content, of: [String: Any].self)
                    for (instanceName, jsonValue) in jsonDict {
                      _ = try info.managedObjectClass.init(info.entityDescription, with: .init(key: instanceName, value: jsonValue), in: context)
                    }
                }
              }
              else {
                _ = try info.managedObjectClass.init(info.entityDescription, with: .init(key: nil, value: [:]), in: context)
              }
          }
        }

        try context.endIngestion()
      }


    init(managedObjectContext: NSManagedObjectContext, objectInfo: [String: ObjectInfo]) throws
      {
        self.managedObjectContext = managedObjectContext
        self.objectInfo = objectInfo
      }


    func beginIngestion()
      {
        precondition(ingesting == false)

        ingesting = true
      }


    func objectInfo(for entityName: String) throws -> ObjectInfo
      {
        guard let info = objectInfo[entityName] else { throw Exception("entity '\(entityName)' is unknown") }
        return info
      }


    func entityDescription(for name: String) throws -> NSEntityDescription
      {
        try objectInfo(for: name).entityDescription
      }


    func fetchObject(id name: String, of entityName: String) throws -> Object
      {
        let fetchRequest = NSFetchRequest<Object>(entityName: entityName)
        fetchRequest.predicate = NSPredicate(format: "name = %@", name)

        let results = try managedObjectContext.fetch(fetchRequest)
        switch results.count {
          case 1 :
            return results[0]
          case 0 :
            throw Exception("no \(entityName) instance with name '\(name)'")
          default :
            throw Exception("multiple \(entityName) instances with name '\(name)'")
        }
      }


    func delay(_ effect: @escaping () throws -> Void)
      {
        precondition(ingesting == true)

        delayedEffects.append(effect)
      }


    func endIngestion() throws
      {
        precondition(ingesting == true)

        // Execute the delayed initialization of object references
        for effect in delayedEffects {
          try effect()
        }

        ingesting = false

        try managedObjectContext.save()
      }
  }
