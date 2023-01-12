/*

*/

import CoreData


/// The base class of managed object.
open class Object : NSManagedObject
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


    /// This method is used to determine whether or not the corresponding NSEntityDescription should be marked abstract, and should only be overridden in classes intended to be abstract by returning their concrete type. The default implementation returns Object.
    open class var abstractClass : Object.Type
      { Object.self }


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


    /// Override init(entity:insertInto:) to be 'required' in order to create instances from class objects. This method is not intended to be overidden.
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      { super.init(entity: entity, insertInto: context) }


    /// Initialize a new instance, taking property values from the given ingest data. This method is not intended to be overidden.
    public required init(_ info: EntityInfo, with ingestData: IngestData, in context: IngestContext) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        super.init(entity: info.entityDescription, insertInto: context.managedObjectContext)

        // Ingest attributes.
        for attribute in info.attributes.values {
          do {
            guard let ingest = attribute.ingest else { continue }
            if let jsonValue = ingestData[ingest.key] {
              let storableValue = try ingest.method(jsonValue)
              setValue(storableValue.storedValue(), forKey: attribute.name)
            }
            else {
              guard attribute.defaultValue != nil || attribute.allowsNilValue else { throw Exception("a value is required") }
            }
          }
          catch let error {
            throw Exception("failed to ingest attribute '\(attribute.name)' of '\(info.name)' -- " + error.localizedDescription)
          }
        }

        // Ingest relationships.
        for relationship in info.relationships.values {
          guard let ingest = relationship.ingest else { continue }
          do {
            let relatedEntity = try context.entityInfo(for: relationship.relatedEntityName)
            let relatedClass = relatedEntity.managedObjectClass
            switch (ingestData[ingest.key], ingest.mode, relationship.arity) {
              case (.some(let jsonValue), .create, let arity) where arity.upperBound > 1 :
                // Creating a to-many relation requires the associated data is a dictionary mapping instance identifiers to the data provided to the related object initializer.
                guard let jsonDict = jsonValue as? [String: Any] else { throw Exception("a dictionary value is required") }
                let relatedObjects = try jsonDict.map { (key, value) in try relatedClass.init(relatedEntity, with: .dictionaryEntry(key: key, value: value), in: context) }
                setValue(Set(relatedObjects), forKey: relationship.name)
              case (.some(let jsonValue), .create, _) :
                // Creating a to-one relationship requires providing the associated data to the related object initializer.
                let relatedObject = try relatedClass.init(relatedEntity, with: .value(jsonValue), in: context)
                setValue(relatedObject, forKey: relationship.name)
              case (.some(let jsonValue), .reference, let arity) where arity.upperBound > 1 :
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
                guard arity.lowerBound == 0 else { throw Exception("a value is required") }
            }
          }
          catch let error {
            throw Exception("failed to ingest relationship '\(relationship.name)' of '\(info.name)' -- " + error.localizedDescription)
          }
        }
      }


    /// Override awakeFromInsert to assign default values to attributes which have default values not assigned by init(entity:insertInto:)
    public override func awakeFromInsert()
      {
        guard let objectInfo = entity.objectInfo else { preconditionFailure("entity \(Unmanaged.passUnretained(entity).toOpaque()) has no assigned ObjectInfo") }

        super.awakeFromInsert()

        for attribute in objectInfo.attributes.values {
          guard let defaultValue = attribute.defaultValue else { continue }
          guard primitiveValue(forKey: attribute.name) == nil else { continue }
          guard let storedValue = try? defaultValue.storedValue() else {
            log("failed to encode default value for \(attribute.name)")
            continue
          }
          setValue(storedValue, forKey: attribute.name)
        }
      }
  }