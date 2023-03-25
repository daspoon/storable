/*

  Created by David Spooner

*/

import CoreData


/// ClassInfo pairs instances of types Entity and NSEntityDescription for a specific subclass of ManagedObject. It exists primarily to enable ingestion of managed objects by providing access to property metadata.

@dynamicMemberLookup
public struct ClassInfo
  {
    public let entityInfo : Entity
    public let entityDescription : NSEntityDescription


    public init(_ entityInfo: Entity, _ entityDescription: NSEntityDescription)
      {
        self.entityInfo = entityInfo
        self.entityDescription = entityDescription
      }


    /// Provide convenient access to the properties of Entity.
    public subscript <Value>(dynamicMember path: KeyPath<Entity, Value>) -> Value
      { entityInfo[keyPath: path] }
  }
