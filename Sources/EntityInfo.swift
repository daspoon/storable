/*

*/

import CoreData


// EntityInfo is a convenience struct combining ObjectInfo and NSEntityDescription.

@dynamicMemberLookup
public struct EntityInfo
  {
    public let objectInfo : ObjectInfo
    public let entityDescription : NSEntityDescription

    public init(_ objectInfo: ObjectInfo, _ entityDescription: NSEntityDescription)
      {
        self.objectInfo = objectInfo
        self.entityDescription = entityDescription
      }


    public subscript <Value>(dynamicMember path: KeyPath<ObjectInfo, Value>) -> Value
      { objectInfo[keyPath: path] }
  }
