/*

  Created by David Spooner

*/

import CoreData


/// ManagedObject is the base class of NSManagedObject which supports model generation and ingestion through managed property wrappers.

open class ManagedObject : NSManagedObject, Codable
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


    open class func propertyName(for keyPath: AnyKeyPath) -> String?
      { nil }


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


    /// Create an instance of the receiving class.
    @objc open dynamic class func createInstance(in context: NSManagedObjectContext) throws -> Self
      { try context.create(Self.self) }


    /// Override init(entity:insertInto:) to be 'required' in order to create instances from class objects. This method is not intended to be overidden.
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      { super.init(entity: entity, insertInto: context) }


    // State restoration

    /// Encode the values of the specified properties to the given container.
    func encodeProperties(_ properties: [String: Property], to container: inout KeyedEncodingContainer<NameCodingKey>) throws
      {
        let changes = changedValues()

        log("saving \(changes.count) changes for \(self.objectID.uriRepresentation())")

        for (name, value) in changes {
          switch properties[name] {
            // Attribute values are encoded w.r.t. their types, which are known only to the given Attribute instance.
            case .attribute(let attribute) :
              if value is NSNull { break }
              log("  \(name)")
              try attribute.encodeValue(value, to: &container)

            // Relationship values are decoded as lists of related object URIs.
            case .relationship(let relationship) :
              let urls : [URL]
              switch relationship.range {
                case .toOptional, .toOne :
                  switch value {
                    case let object as ManagedObject :
                      urls = [object.objectID.uriRepresentation()]
                    case is NSNull :
                      urls = []
                    default :
                      throw Exception("unexpected value type for \(type(of: self)).\(name): \(type(of: value))")
                  }
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
        log("restoring changes for \(self.objectID.uriRepresentation())")

        for key in container.allKeys {
          switch properties[key.name] {
            // Attribute values are decoded w.r.t. their types, which are known only to the given Attribute instance.
            case .attribute(let attribute) :
              let value = try attribute.decodeValue(from: &container)
              log("  \(key.name)")
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


    /// Retrieve the value of a non-optional attribute.
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


    /// Retrieve the value of an optional attribute.
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


    /// Set the value of a non-optional attribute.
    public func setAttributeValue<Value: Storable>(_ value: Value, forKey key: String)
      { setValue(value.storedValue(), forKey: key) }


    /// Set the value of an optional attribute.
    public func setAttributeValue<Value: Nullable>(_ value: Value, forKey key: String) where Value.Wrapped : Storable
      { setValue(Value.project(value)?.storedValue(), forKey: key) }


    // MARK: - Decodable

    public required init(from coder: Decoder) throws
      {
        // Get the required context from the coder's userInfo
        guard let decodingContext = coder.userInfo[ImportContext.codingUserInfoKey] as? ImportContext
          else { throw Exception("decoder's userInfo must contain a ImportContext instance for key ImportContext.codingUserInfoKey") }

        // Note: for generic subclasses of ManagedObject, Self.self == ManagedObject.self; thus we take the receiver's entity description and dynamic type from the decoding state.
        guard let entity = decodingContext.allocatingEntity
          else { throw Exception("allocatingEntity is nil") }

        super.init(entity: entity.entityDescription, insertInto: decodingContext.managedObjectContext)

        // Get the keyed container from which to decode our properties
        var container = try coder.container(keyedBy: NameCodingKey.self)

        // Iterate over the declared properties to initialize our property values
        for (name, property) in entity.objectType.declaredPropertiesByName {
          switch property {
            case .attribute(let attribute) :
              // Attribute instances are responsible for decoding their values as CoreData-native types
              guard let value = try attribute.decodeValue(from: &container) else { break }
              setValue(value, forKey: name)

            case .relationship(let relationship) :
              // Do nothing if the relationship is not encoded
              guard case .some(let encoding) = relationship.ingest
                else { break }
              // Get the related class
              guard let relatedInfo = decodingContext.dataStore.classInfoByName[relationship.relatedEntityName]
                else { throw Exception("failed to resolve related entity name of \(type(of: self)).\(relationship.name): \(relationship.relatedEntityName)") }
              // Decode and assign the related objects
              decodingContext.pushAllocatingEntity(relatedInfo)
              switch relationship.range {
                case .toOptional, .toOne :
                  switch encoding.mode {
                    case .reference :
                      guard let url = try container.decodeIfPresent(URL.self, forKey: .init(name: name)) else { break }
                      decodingContext.delayedAddObject(with: url, to: relationship, of: self)
                    case .create(_) : // TODO: account for format
                      guard let object = try container.decodeIfPresent(relatedInfo.objectType, forKey: .init(name: name)) else { break }
                      setValue(object, forKey: name)
                      decodingContext.callback?(object)
                  }
                default :
                  var subcontainer = try container.nestedUnkeyedContainer(forKey: .init(name: name))
                  while subcontainer.isAtEnd == false {
                    switch encoding.mode {
                      case .reference :
                        let url = try subcontainer.decode(URL.self)
                        decodingContext.delayedAddObject(with: url, to: relationship, of: self)
                      case .create(_) : // TODO: account for format; enture mutableSetValue(forKey:) is cached
                        let object = try subcontainer.decode(relatedInfo.objectType)
                        mutableSetValue(forKey: name).add(object)
                        decodingContext.callback?(object)
                    }
                  }
              }
              decodingContext.popAllocatingEntity()

            default :
              break
          }
        }
      }


    // MARK: - Encodable

    public func encode(to encoder: Encoder) throws
      {
        // Create a keyed container to encode object properties
        var container = encoder.container(keyedBy: NameCodingKey.self)

        // Iterate over declared properties to encode relationships and non-transient attributes; ignore fetched properties.
        for (name, property) in Self.declaredPropertiesByName {
          let value = value(forKey: name)

          switch property {
            case .attribute(let attribute) :
              guard let value else { break }
              try attribute.encodeValue(value, to: &container)

            case .relationship(let relationship) :
              // Do nothing if the relationship is not encoded
              guard case .some(let encoding) = relationship.ingest
                else { break }

              // Extract the set of related objects
              switch (relationship.range, value) {
                case (.toOptional, .none) :
                  break
                case (.toOne, .some(let object as ManagedObject)), (.toOptional, .some(let object as ManagedObject)) :
                  switch encoding.mode {
                    case .reference :
                      try container.encode(object.objectID.uriRepresentation(), forKey: NameCodingKey(name: name))
                    case .create(_) : // TODO: account for format
                      try container.encode(object, forKey: NameCodingKey(name: name))
                  }
                case (_, .some(let objects as Set<ManagedObject>)) :
                  switch encoding.mode {
                    case .reference :
                      try container.encode(objects.map {$0.objectID.uriRepresentation()}, forKey: NameCodingKey(name: name))
                    case .create(_) : // TODO: account for format
                      try container.encode(objects, forKey: NameCodingKey(name: name))
                  }
                default :
                  throw Exception("unexpected value type for \(type(of: self)).\(name): \(type(of: value))")
              }

            case .fetched(_) :
              break
          }
        }
      }
  }
