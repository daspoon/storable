/*

*/

import CoreData


/// The base class of managed object.
open class ManagedObject : NSManagedObject
  {
    /// The notion of instance identity (within class).
    public enum Identity : String, Ingestible
      {
        /// There is no inherent identity.
        case anonymous
        /// Identity is given by the string value of the 'name' attribute.
        case name
        /// There is a single instance of the entity.
        case singleton
      }


    public class var entityName : String
      { "\(Self.self)" }


    open class var identity : Identity
      { .anonymous }


    /// Return a mirror for instances of this class.
    class var instanceMirror : Mirror
      {
        let entityName = Self.entityName

        let templateObjectModel = NSManagedObjectModel()
        let templateEntity = NSEntityDescription()
        templateEntity.name = entityName
        templateEntity.managedObjectClassName = entityName
        templateObjectModel.entities = [templateEntity]

        return Mirror(reflecting: Self.init(entity: templateEntity, insertInto: nil))
      }


    /// This method is 'required' because it is invoked on class objects. This method is not intended to be overidden.
    public override required init(entity desc: NSEntityDescription, insertInto ctx: NSManagedObjectContext?)
      { super.init(entity: desc, insertInto: ctx) }


    /// Initialize a new instance, assigning default attribute values. This method is not intended to be overidden.
    public required init(_ entity: ManagedEntity, in managedObjectContext: NSManagedObjectContext) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        super.init(entity: entity.entityDescription, insertInto: managedObjectContext)

        // Assign default attribute values
        for attribute in entity.attributes.values {
          guard let defaultValue = attribute.defaultValue else { continue }
          setValue(try defaultValue.storedValue(), forKey: attribute.name)
        }
      }


    /// Initialize a new instance, taking property values from the given ingest data. This method is not intended to be overidden.
    public required init(_ entity: ManagedEntity, with ingestData: IngestData, in context: IngestContext) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        super.init(entity: entity.entityDescription, insertInto: context.managedObjectContext)

        // Ingest attributes.
        for attribute in entity.attributes.values {
          do {
            let storableValue : (any Storable)?
            if let ingest = attribute.ingest {
              switch (ingestData[ingest.key], attribute.defaultValue) {
                case (.some(let jsonValue), _) :
                  storableValue = try ingest.method(jsonValue)
                case (.none, .some(let defaultValue)) :
                  storableValue = defaultValue
                case (.none, .none) :
                  storableValue = nil
              }
            }
            else {
              storableValue = attribute.defaultValue
            }
            guard storableValue != nil || attribute.allowsNilValue else { throw Exception("a value is required") }
            setValue(try storableValue?.storedValue(), forKey: attribute.name)
          }
          catch let error {
            throw Exception("failed to ingest attribute '\(attribute.name)' of '\(entity.name)' -- " + error.localizedDescription)
          }
        }

        // Ingest relationships.
        for relationship in entity.relationships.values {
          guard let ingest = relationship.ingest else { continue }
          do {
            let relatedEntity = try context.entity(for: relationship.relatedEntityName)
            let relatedClass = relatedEntity.managedObjectClass
            switch (ingestData[ingest.key], ingest.mode, relationship.arity) {
              case (.some(let jsonValue), .create, .toMany) :
                // Creating a to-many relation requires the associated data is a dictionary mapping instance identifiers to the data provided to the related object initializer.
                guard let jsonDict = jsonValue as? [String: Any] else { throw Exception("a dictionary value is required") }
                let relatedObjects = try jsonDict.map { (key, value) in try relatedClass.init(relatedEntity, with: .dictionaryEntry(key: key, value: value), in: context) }
                setValue(Set(relatedObjects), forKey: relationship.name)
              case (.some(let jsonValue), .create, _) :
                // Creating a to-one relationship requires providing the associated data to the related object initializer.
                let relatedObject = try relatedClass.init(relatedEntity, with: .value(jsonValue), in: context)
                setValue(relatedObject, forKey: relationship.name)
              case (.some(let jsonValue), .reference, .toMany) :
                // A to-many reference requires an array string instance identifiers. Evaluation is delayed until all entity instances have been created.
                guard let instanceIds = jsonValue as? [String] else { throw Exception("an array of object identifiers is required") }
                context.delay {
                  let relatedObjects = try instanceIds.map { try context.fetchObject(id: $0, of: relatedEntity.name) }
                  self.setValue(Set(relatedObjects), forKey: relationship.name)
                }
              case (.some(let jsonValue), .reference, _) :
                // A to-one reference requires a string instance identifier. Evaluation is delayed until all entity instances have been created.
                guard let instanceId = jsonValue as? String else { throw Exception("an object identifier is required") }
                context.delay {
                  let relatedObject = try context.fetchObject(id: instanceId, of: relatedEntity.name)
                  self.setValue(relatedObject, forKey: relationship.name)
                }
              case (.none, _, let arity) :
                guard arity == .toMany || arity == .optionalToOne else { throw Exception("a value is required") }
            }
          }
          catch let error {
            throw Exception("failed to ingest relationship '\(relationship.name)' of '\(entity.name)' -- " + error.localizedDescription)
          }
        }
      }
  }
