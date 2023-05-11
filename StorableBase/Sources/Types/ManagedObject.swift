/*

  Created by David Spooner

*/

import CoreData


/// ManagedObject is the base class of NSManagedObject which supports model generation and ingestion through managed property wrappers.

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


    open class var declaredPropertiesByName : [String: Property]
      { [:] }


    /// Return the name of the defined entity.
    public class var entityName : String
      { entityNameAndVersion.entityName }


    private static let entityNameAndVersionRegex = try! NSRegularExpression(pattern: "(\\w+)_v(\\d+)", options: [])

    /// Return the pairing of defined entity name and version number by applying the regular expression (\w+)_v(\d+) to the receiver's name.
    /// If no there is no unique match then the entity name is taken to be the receiver's name and the version is taken to be zero.
    open class var entityNameAndVersion : (entityName: String, version: Int)
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


    /// Return the notion of instance identify for the purpose of relationship ingestion. The default implementation returns anonymous.
    open class var identity : Identity
      { .anonymous }


    /// This method is used to determine whether or not the corresponding NSEntityDescription should be marked abstract, and should only be overridden in classes intended to be abstract by returning their concrete type. The default implementation returns ManagedObject.
    open class var abstractClass : ManagedObject.Type
      { ManagedObject.self }


    /// Return true iff the receiver is intended to represent an abstract entity.
    public class var isAbstract : Bool
      { Self.self == abstractClass }


    /// Override init(entity:insertInto:) to be 'required' in order to create instances from class objects. This method is not intended to be overidden.
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      { super.init(entity: entity, insertInto: context) }


    /// Initialize a new instance, taking property values from the given ingest data. This method is not intended to be overidden.
    public required init(_ info: ClassInfo, with ingestData: IngestObject, in store: DataStore, delay: (@escaping () throws -> Void) -> Void) throws
      {
        // Delegate to the designated initializer for NSManagedObject.
        super.init(entity: info.entityDescription, insertInto: store.managedObjectContext)

        // Ingest attributes.
        for attribute in info.attributes.values {
          do {
            guard let ingest = attribute.ingest else { continue }
            if let jsonValue = ingestData[ingest.key] {
              let storableValue = try ingest.method(jsonValue)
              setValue(storableValue, forKey: attribute.name)
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
            let relatedInfo = try store.classInfo(for: relationship.relatedEntityName)
            let relatedClass = relatedInfo.managedObjectClass
            switch (ingestData[ingest.key], ingest.mode, relationship.range) {
              case (.some(let jsonValue), .create(let format), let range) where range.upperBound > 1 :
                // When creating a to-many relationship, the format parameter determines the type and interpretation of the json data...
                let relatedObjects = try relatedInfo.createObjects(from: jsonValue, with: format, in: store, delay: delay)
                setValue(Set(relatedObjects), forKey: relationship.name)
              case (.some(let jsonValue), .create(let format), _) :
                // When creating a to-one relationship, the json data is interpreted by the object initializer
                guard format == .any else { throw Exception("") }
                let relatedObject = try relatedInfo.createObject(from: jsonValue, in: store, delay: delay)
                setValue(relatedObject, forKey: relationship.name)
              case (.some(let jsonValue), .reference, let range) where range.upperBound > 1 :
                // A to-many reference requires an array string instance identifiers. Evaluation is delayed until all entity instances have been created.
                guard let instanceIds = jsonValue as? [String] else { throw Exception("an array of object identifiers is required") }
                delay {
                  let relatedObjects = try instanceIds.map { try store.managedObjectContext.fetchObject(id: $0, of: relatedClass) }
                  self.setValue(Set(relatedObjects), forKey: relationship.name)
                }
              case (.some(let jsonValue), .reference, _) :
                // A to-one reference requires a string instance identifier. Evaluation is delayed until all entity instances have been created.
                guard let instanceId = jsonValue as? String else { throw Exception("an object identifier is required") }
                delay {
                  let relatedObject = try store.managedObjectContext.fetchObject(id: instanceId, of: relatedClass)
                  self.setValue(relatedObject, forKey: relationship.name)
                }
              case (.none, _, let range) :
                guard range.lowerBound == 0 else { throw Exception("a value is required") }
            }
          }
          catch let error {
            throw Exception("failed to ingest relationship '\(relationship.name)' of '\(info.name)' -- " + error.localizedDescription)
          }
        }
      }


    // Retrieve the value of a non-optional attribute.

    public func attributeValue<Value: StorageType>(forKey key: String) -> Value
      {
        switch self.value(forKey: key) {
          case .some(let objectValue) :
            guard let value = objectValue as? Value
              else { fatalError("\(key) is not of expected type \(Value.self)") }
            return value
          case .none :
            fatalError("\(key) is not initialized")
        }
      }

    public func attributeValue<Value: Storable>(forKey key: String) -> Value
      {
        switch self.value(forKey: key) {
          case .some(let objectValue) :
            guard let encodedValue = objectValue as? Value.EncodingType
              else { fatalError("\(key) is not of expected type \(Value.EncodingType.self)") }
            return Value.decodeStoredValue(encodedValue)
          case .none :
            fatalError("\(key) is not initialized")
        }
      }


    // Retrieve the value of an optional attribute.

    public func attributeValue<Value: Nullable>(forKey key: String) -> Value where Value.Wrapped : StorageType
      {
        switch value(forKey: key) {
          case .some(let objectValue) :
            guard let value = objectValue as? Value.Wrapped
              else { fatalError("\(key) is not of expected type \(Value.Wrapped.self)") }
            return Value.inject(value)
          case .none :
            return nil
        }
      }

    public func attributeValue<Value: Nullable>(forKey key: String) -> Value where Value.Wrapped : Storable
      {
        switch value(forKey: key) {
          case .some(let objectValue) :
            guard let encodedValue = objectValue as? Value.Wrapped.EncodingType
              else { fatalError("\(key) is not of expected type \(Value.Wrapped.EncodingType.self)") }
            return Value.inject(Value.Wrapped.decodeStoredValue(encodedValue))
          case .none :
            return nil
        }
      }


    // Set the value of a non-optional attribute.

    public func setAttributeValue<Value: StorageType>(_ value: Value, forKey key: String)
      { setValue(value, forKey: key) }

    public func setAttributeValue<Value: Storable>(_ value: Value, forKey key: String)
      { setValue(value.storedValue(), forKey: key) }


    // Set the value of an optional attribute.

    public func setAttributeValue<Value: Nullable>(_ value: Value, forKey key: String) where Value.Wrapped : StorageType
      { setValue(Value.project(value), forKey: key) }

    public func setAttributeValue<Value: Nullable>(_ value: Value, forKey key: String) where Value.Wrapped : Storable
      { setValue(Value.project(value)?.storedValue(), forKey: key) }
  }
