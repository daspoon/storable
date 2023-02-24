/*

*/

import CoreData


extension NSManagedObjectModel
  {
    /// Assuming the receiver was constructed via Schema's createRuntimeInfo method, return the associated schema version identifier.
    var versionId : String
      {
        guard let entity = entitiesByName[Schema.versioningEntityName] else { fatalError() }
        return entity.versionHashModifier!
      }
  }
