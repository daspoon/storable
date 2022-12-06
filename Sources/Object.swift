/*

*/

import CoreData


/// The base class of managed object.
open class Object : NSManagedObject
  {
    /// Specifies how property value are established on instance initialization.
    public struct PropertyIngestDescriptor
      {
        let propertyName : String
        let optional : Bool
        let ingestKey : IngestKey
        let ingestAction : IngestAction

        public enum IngestAction
          {
            case assign((Any) throws -> NSObject)
            case relate(relatedEntityName: String, arity: Relationship.Arity, ingestMode: Relationship.IngestMode)
          }

        public init(_ name: String, ingestKey k: IngestKey, ingestAction a: IngestAction, optional o: Bool)
          {
            propertyName = name
            ingestKey = k
            ingestAction = a
            optional = o
          }
      }


    /// Subclasses are responsible for specifying this translation of json data to instance property values.
    open class var propertyIngestDescriptors : [PropertyIngestDescriptor]
      { fatalError("subclass responsibility") }


    /// Initialize a new instance with the given ingestion data. The name parameter must be provided iff instances of this class are retrieved by name.
    public required convenience init(_ entity: NSEntityDescription, with ingestData: IngestData, in context: IngestContext) throws
      {
        // Delegate to the designated initializer.
        self.init(entity: entity, insertInto: context.managedObjectContext)

        // Initialize the other model properties from the ingest data.
        for descriptor in Self.propertyIngestDescriptors {
          // Ensure a value is given if required.
          guard let jsonValue = ingestData[descriptor.ingestKey] else {
            guard descriptor.optional else { throw Exception("'\(descriptor.ingestKey)' requires a value") }
            continue
          }

          // Defer to the attribute or relation to perform ingestion, catching any exceptions thrown by those implementations.
          do {
            switch descriptor.ingestAction {
              case .assign(let ingest) :
                setValue(try ingest(jsonValue), forKey: descriptor.propertyName)

              case .relate(let relatedEntityName, let arity, let ingestMode) :
                let (relatedEntity, relatedClass) = try context.objectInfo(for: relatedEntityName)

                // The action taken depends on the ingestion mode and the arity of the relationship...
                switch (ingestMode, arity) {
                  case (.create, .toMany) :
                    // Creating a to-many relation requires the associated data is a dictionary mapping instance identifiers to the data provided to the related object initializer.
                    guard let jsonDict = jsonValue as? [String: Any] else { throw Exception("'\(descriptor.ingestKey)' requires a dictionary value") }
                    let relatedObjects = try jsonDict.map { (key, value) in try relatedClass.init(relatedEntity, with: IngestData(key: key, value: value), in: context) }
                    setValue(Set(relatedObjects), forKey: descriptor.propertyName)

                  case (.create, _) :
                    // Creating a to-one relationship requires providing the associated data to the related object initializer.
                    let relatedObject = try relatedClass.init(relatedEntity, with: .init(value: jsonValue), in: context)
                    setValue(relatedObject, forKey: descriptor.propertyName)

                  case (.reference, .toMany) :
                    // A to-many reference requires an array string instance identifiers. Evaluation is delayed until all entity instances have been created.
                    guard let instanceIds = jsonValue as? [String] else { throw Exception("'\(descriptor.ingestKey)' requires an array of object identifiers") }
                    context.delay {
                      let relatedObjects = try instanceIds.map { try context.fetchObject(id: $0, of: relatedEntityName) }
                      self.setValue(Set(relatedObjects), forKey: descriptor.propertyName)
                    }
                  case (.reference, _) :
                    // A to-one reference requires a string instance identifier. Evaluation is delayed until all entity instances have been created.
                    guard let instanceId = jsonValue as? String else { throw Exception("'\(descriptor.ingestKey)' requires an object identifier") }
                    context.delay {
                      let relatedObject = try context.fetchObject(id: instanceId, of: relatedEntityName)
                      self.setValue(relatedObject, forKey: descriptor.propertyName)
                    }
                }
            }
          }
          catch let error {
            throw Exception("failed to ingest '\(descriptor.ingestKey)' -- " + error.localizedDescription)
          }
        }
      }
  }
