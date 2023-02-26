/*

*/

import CoreData


/// IngestContext provides an interface for populating a DataStore...

@dynamicMemberLookup
public class IngestContext
  {
    let dataStore : DataStore

    private var ingesting : Bool = false
    private var delayedEffects : [() throws -> Void] = []


    static func populate(dataStore: DataStore, from dataSource: DataSource) throws
      {
        let context = try IngestContext(dataStore: dataStore)

        context.beginIngestion()

        // Ingest each defined type
        for definition in dataSource.definitions {
          log(definition.ingestDescription)
          try definition.ingest(from: dataSource, into: context)
        }

        try context.endIngestion()
      }


    init(dataStore s: DataStore) throws
      {
        dataStore = s
      }


    public subscript <Value>(dynamicMember path: KeyPath<DataStore, Value>) -> Value
      { dataStore[keyPath: path] }


    func beginIngestion()
      {
        precondition(ingesting == false)

        ingesting = true
      }


    public func entityInfo(for entityName: String) throws -> EntityInfo
      {
        guard let entity = dataStore.entityInfoByName[entityName] else { throw Exception("unknown entity name '\(entityName)'") }
        return entity
      }


    public func entityInfo(for type: Object.Type) throws -> EntityInfo
      {
        try entityInfo(for: type.entityName)
      }


    public func fetchObject<T: Object>(id name: String, of type: T.Type = T.self) throws -> T
      {
        try dataStore.managedObjectContext.fetchObject(makeFetchRequest(for: type, predicate: .init(format: "name = %@", name)))
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

        try dataStore.save()
      }
  }
