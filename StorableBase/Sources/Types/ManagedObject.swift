/*

  Created by David Spooner

*/

import CoreData


/// ManagedObject is the base class of NSManagedObject which supports model generation and ingestion through managed property wrappers.

open class ManagedObject : NSManagedObject
  {
    /// The notion of instance identity (within class).
    public enum Identity : String
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


    // State restoration

    /// Encode the values of the specified properties to the given container.
    func encodeProperties(_ properties: [String: Property], to container: inout KeyedEncodingContainer<NameCodingKey>) throws
      {
        let changes = changedValues()
        log("saving \(changes.count) changes for \(objectID.uriRepresentation())")

        for (name, value) in changes {
          // TODO: account for NSNull used to represent nil
          switch properties[name] {
            // Attribute values are encoded w.r.t. their types, which are known only to the given Attribute instance.
            case .attribute(let attribute) :
              log("  \(name) -> \(value)")
              try attribute.encodeValue(value, to: &container)

            // Relationship values are decoded as lists of related object URIs.
            case .relationship(let relationship) :
              let urls : [URL]
              switch relationship.range {
                case .toOptional, .toOne :
                  guard let object = value as? ManagedObject else { throw Exception("unexpected value type for \(type(of: self)).\(name): \(type(of: value))") }
                  urls = [object.objectID.uriRepresentation()]
                default :
                  guard let objects = value as? Set<ManagedObject> else { throw Exception("unexpected value type for \(type(of: self)).\(name): \(type(of: value))") }
                  urls = objects.map { $0.objectID.uriRepresentation() }
              }
              log("  \(name) -> \(urls)")
              try container.encode(urls, forKey: .init(name: name))

            // Fetched properties are not encoded.
            case .fetched(_) :
              break

            default :
              throw Exception("unexpected property: \(name)")
          }
        }
      }

    /// Decode the values of the specified properties from the given container.
    func decodeProperties(_ properties: [String: Property], from container: inout KeyedDecodingContainer<NameCodingKey>, objectByURL: (URL) throws -> ManagedObject) throws
      {
        log("restoring \(container.allKeys.count) changes for \(objectID.uriRepresentation())")

        for key in container.allKeys {
          switch properties[key.name] {
            // Attribute values are decoded w.r.t. their types, which are known only to the given Attribute instance.
            case .attribute(let attribute) :
              let value = try attribute.decodeValue(from: &container)
              log("  \(key.name) <- \(value ?? "nil")")
              setValue(value, forKey: key.name)

            // Relationship values are decoded as lists of object URIs, which must be mapped to object instances by the given context.
            case .relationship(let relationship) :
              let urls = try container.decode([URL].self, forKey: .init(name: key.name))
              log("  \(key.name) <- \(urls)")
              let objects = try urls.map { try objectByURL($0) }
              switch relationship.range {
                case .toOptional, .toOne :
                  guard objects.count <= 1 else { throw Exception("invalid related object count for \(type(of: self)).\(key.name): \(objects.count)") }
                  setValue(objects.first, forKey: key.name)
                default :
                  setValue(Set(objects), forKey: key.name)
              }

            // Fetched properties are not encoded.
            case .fetched(_) :
              break

            default :
              throw Exception("unexpected property: \(key.name)")
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
