/*

  Created by David Spooner

*/

import CoreData


/// ManagedObject is the base class of NSManagedObject which supports model generation and ingestion through managed property wrappers.

open class ManagedObject : NSManagedObject
  {
    open class var declaredPropertiesByName : [String: Property]
      { [:] }


    /// Return the name of the defined entity.
    public class var entityName : String
      { entityNameAndVersion.entityName }


    private static let entityNameAndVersionRegex = try! NSRegularExpression(pattern: "(\\w+)_v(\\d+)", options: [])

    /// Return the pairing of defined entity name and version number by applying the regular expression (\w+)_v(\d+) to the receiver's name.
    /// If no there is no unique match then the entity name is taken to be the receiver's name and the version is taken to be zero.
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


    /// This method is used to determine whether or not the corresponding NSEntityDescription should be marked abstract, and should only be overridden in classes intended to be abstract by returning their concrete type. The default implementation returns ManagedObject.
    open class var abstractClass : ManagedObject.Type
      { ManagedObject.self }


    /// Return true iff the receiver is intended to represent an abstract entity.
    public class var isAbstract : Bool
      { Self.self == abstractClass }


    /// Override init(entity:insertInto:) to be 'required' in order to create instances from class objects. This method is not intended to be overidden.
    public required override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?)
      { super.init(entity: entity, insertInto: context) }
  }
