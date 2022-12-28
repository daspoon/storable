/*

*/

import CoreData


/// The base class of managed object.
open class Object : NSManagedObject
  {
    public class var entityName : String
      { "\(Self.self)" }


    open class var identity : Identity
      { .anonymous }


    /// Return a mapping of names to Property values, corresponding to the instance variables declared with property wrappers conforming to ManagedPropertyWrapper.
    class var properties : [(String, Property)]
      {
        let entityName = Self.entityName

        // Create a mirror on an empty instance; this requires an empty entity description attached to a managed object model.
        let templateObjectModel = NSManagedObjectModel()
        let templateEntity = NSEntityDescription()
        templateEntity.name = entityName
        templateEntity.managedObjectClassName = entityName
        templateObjectModel.entities = [templateEntity]
        let mirror = Mirror(reflecting: Self.init(entityDescription: templateEntity))

        return mirror.children.compactMap { label, value in
          guard let wrapper = value as? ManagedPropertyWrapper else { return nil }
          guard let label, label.hasPrefix("_") else { return nil }
          return (label.removing(prefix: "_"), wrapper.property)
        }
      }


    /// This method is used to create an non-functional instance for the purpose of reflection. It is 'required' because it is invoked on a class object, and thus also 'public'.
    public required convenience init(entityDescription: NSEntityDescription)
      { self.init(entity: entityDescription, insertInto: nil) }


    /// Initialize a new instance with the given ingestion data. The name parameter must be provided iff instances of this class are retrieved by name.
    public required convenience init(_ entity: Entity, with ingestData: IngestData, in context: IngestContext) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        self.init(entity: entity.entityDescription, insertInto: context.managedObjectContext)

        // Initialize property values from the ingest data
        for property in entity.properties.values {
          do {
            if let jsonValue = ingestData[property.ingestKey] {
              switch property {
                case let attribute as Attribute :
                  setValue(try attribute.ingestMethod(jsonValue).storedValue(), forKey: attribute.name)

                case let relationship as Relationship :
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
              guard property.defaultIngestValue != nil || property.allowsNilValue else { throw Exception("a value is required") }
              setValue(try property.defaultIngestValue?.storedValue(), forKey: property.name)
            }
          }
          catch let error {
            throw Exception("failed to ingest '\(entity.name).\(property.ingestKey)' -- " + error.localizedDescription)
          }
        }
      }
  }
