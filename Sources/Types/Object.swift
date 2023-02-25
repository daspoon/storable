/*

*/

import CoreData


/// Object is the base class of NSManagedObject which supports model generation and ingestion through managed property wrappers.

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
      { entityNameAndVersion.entityName }


    private static let entityNameAndVersionRegex = try! NSRegularExpression(pattern: "(\\w+)_v(\\d+)", options: [])

    class var entityNameAndVersion : (entityName: String, version: Int)
      {
        let objcName = "\(Self.self)" as NSString
        let objcNameRange = NSMakeRange(0, objcName.length)

        let matches = entityNameAndVersionRegex.matches(in: (objcName as String), options: [], range: objcNameRange)

        return matches.count == 1 && matches[0].range == objcNameRange
          ? (
            entityName: objcName.substring(with: matches[0].range(at: 1)) as String,
            version: Int(objcName.substring(with: matches[0].range(at: 2)))!
          )
          : (entityName: objcName as String, version: 0)
      }


    /// This method must be overridden to return non-nil if and only if the previous version exists with a different entity name. The default implementation returns nil.
    open class var renamingIdentifier : String?
      { nil }


    open class var identity : Identity
      { .anonymous }


    /// This method is used to determine whether or not the corresponding NSEntityDescription should be marked abstract, and should only be overridden in classes intended to be abstract by returning their concrete type. The default implementation returns Object.
    open class var abstractClass : Object.Type
      { Object.self }


    /// Return true iff the receiver is intended to represent an abstract entity.
    public class var isAbstract : Bool
      { Self.self == abstractClass }


    /// Return a mirror for instances of this class.
    class var instanceMirror : Mirror
      {
        let templateObjectModel = NSManagedObjectModel()
        let templateEntity = NSEntityDescription()
        templateEntity.name = Self.entityName
        templateEntity.managedObjectClassName = NSStringFromClass(Self.self)
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
              guard attribute.defaultValue != nil || attribute.isOptional else { throw Exception("a value is required") }
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
              case (.some(let jsonValue), .create(let format), let arity) where arity.upperBound > 1 :
                // When creating a to-many relationship, the format parameter determines the type and interpretation of the json data...
                let relatedObjects = try relatedEntity.createObjects(from: jsonValue, with: format, in: context)
                setValue(Set(relatedObjects), forKey: relationship.name)
              case (.some(let jsonValue), .create(let format), _) :
                // When creating a to-one relationship, the json data is interpreted by the object initializer
                guard format == .any else { throw Exception("") }
                let relatedObject = try relatedEntity.createObject(from: jsonValue, in: context)
                setValue(relatedObject, forKey: relationship.name)
              case (.some(let jsonValue), .reference, let arity) where arity.upperBound > 1 :
                // A to-many reference requires an array string instance identifiers. Evaluation is delayed until all entity instances have been created.
                guard let instanceIds = jsonValue as? [String] else { throw Exception("an array of object identifiers is required") }
                context.delay {
                  let relatedObjects = try instanceIds.map { try context.fetchObject(id: $0, of: relatedClass) }
                  self.setValue(Set(relatedObjects), forKey: relationship.name)
                }
              case (.some(let jsonValue), .reference, _) :
                // A to-one reference requires a string instance identifier. Evaluation is delayed until all entity instances have been created.
                guard let instanceId = jsonValue as? String else { throw Exception("an object identifier is required") }
                context.delay {
                  let relatedObject = try context.fetchObject(id: instanceId, of: relatedClass)
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
  }
