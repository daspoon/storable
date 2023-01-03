/*

*/

import CoreData


/// The base class of managed object.
open class ManagedObject : NSManagedObject
  {
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


    /// This method is used to create an non-functional instance for the purpose of reflection. It is 'required' because it is invoked on a class object, and thus also 'public'.
    public override required init(entity desc: NSEntityDescription, insertInto ctx: NSManagedObjectContext?)
      { super.init(entity: desc, insertInto: ctx) }


    /// Initialize a new instance with the given ingestion data. The name parameter must be provided iff instances of this class are retrieved by name.
    public required convenience init(_ entity: ManagedEntity, with ingestData: IngestData, in context: IngestContext) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        self.init(entity: entity.entityDescription, insertInto: context.managedObjectContext)

        // Initialize property values from the ingest data
        for property in entity.properties.values {
          do {
            switch property.ingestAction {
              case .ingest(key: let key, defaultValue: let defaultValue) :
                if let jsonValue = ingestData[key] {
                  switch property {
                    case let attribute as ManagedAttribute :
                      setValue(try attribute.ingestMethod(jsonValue).storedValue(), forKey: attribute.name)
                    case let relationship as ManagedRelationship :
                      // The action taken depends on the ingestion mode and the arity of the relationship...
                      let relatedEntity = try context.entity(for: relationship.relatedEntityName)
                      let relatedClass = relatedEntity.managedObjectClass
                      switch (relationship.ingestMode, relationship.arity) {
                        case (.create, .toMany) :
                          // Creating a to-many relation requires the associated data is a dictionary mapping instance identifiers to the data provided to the related object initializer.
                          guard let jsonDict = jsonValue as? [String: Any] else { throw Exception("a dictionary value is required") }
                          let relatedObjects = try jsonDict.map { (key, value) in try relatedClass.init(relatedEntity, with: .dictionaryEntry(key: key, value: value), in: context) }
                          setValue(Set(relatedObjects), forKey: relationship.name)
                        case (.create, _) :
                          // Creating a to-one relationship requires providing the associated data to the related object initializer.
                          let relatedObject = try relatedClass.init(relatedEntity, with: .value(jsonValue), in: context)
                          setValue(relatedObject, forKey: relationship.name)
                        case (.reference, .toMany) :
                          // A to-many reference requires an array string instance identifiers. Evaluation is delayed until all entity instances have been created.
                          guard let instanceIds = jsonValue as? [String] else { throw Exception("an array of object identifiers is required") }
                          context.delay {
                            let relatedObjects = try instanceIds.map { try context.fetchObject(id: $0, of: relatedEntity.name) }
                            self.setValue(Set(relatedObjects), forKey: relationship.name)
                          }
                        case (.reference, _) :
                          // A to-one reference requires a string instance identifier. Evaluation is delayed until all entity instances have been created.
                          guard let instanceId = jsonValue as? String else { throw Exception("an object identifier is required") }
                          context.delay {
                            let relatedObject = try context.fetchObject(id: instanceId, of: relatedEntity.name)
                            self.setValue(relatedObject, forKey: relationship.name)
                          }
                      }
                    default :
                      fatalError("unsupported property type: \(type(of: property))")
                  }
                }
                else {
                  guard defaultValue != nil || property.allowsNilValue else { throw Exception("a value is required") }
                  setValue(try defaultValue?.storedValue(), forKey: property.name)
                }
              case .initialize(initialValue: let initialValue) :
                guard initialValue != nil || property.allowsNilValue else { throw Exception("an initial value is required") }
                setValue(try initialValue?.storedValue(), forKey: property.name)
              case .ignore :
                break
            }
          }
          catch let error {
            throw Exception("failed to ingest '\(entity.name).\(property.name)' -- " + error.localizedDescription)
          }
        }
      }
  }
