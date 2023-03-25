/*

  Created by David Spooner

*/

import CoreData


/// Entity maintains the metadata for a subclass of ManagedObject; it is analogous to CoreData's NSEntityDescription.

public struct Entity
  {
    public let name : String
    public private(set) var attributes : [String: Attribute] = [:]
    public private(set) var relationships : [String: Relationship] = [:]
    public private(set) var fetchedProperties : [String: Fetched] = [:]
    public let managedObjectClass : ManagedObject.Type


    /// Create a new instance for the given subclass of ManagedObject.
    public init(objectType: ManagedObject.Type) throws
      {
        name = objectType.entityName
        managedObjectClass = objectType

        for (name, info) in objectType.declaredPropertiesByName {
          switch info {
            case .attribute(let info) :
              attributes[name] = info
            case .relationship(let info) :
              relationships[name] = info
            case .fetched(let info) :
              fetchedProperties[name] = info
          }
        }
      }


    public var isAbstract : Bool
      { managedObjectClass.isAbstract }
  }


// MARK: --

/// The ManagedObject macro, when applied to definitions of ManagedObject subclasses, generates instances of the ManagedObject struct.

@attached(member, names: named(declaredPropertiesByName))
public macro ManagedObject() = #externalMacro(module: "StorableMacros", type: "EntityMacro")
