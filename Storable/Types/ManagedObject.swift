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
      { "\(Self.self)" }


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
