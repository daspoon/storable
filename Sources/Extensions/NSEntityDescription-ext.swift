/*

*/

import CoreData


fileprivate var objectInfoKey : Int = 0


extension NSEntityDescription
  {
    /// The ObjectInfo struct assigned by Schema on creation of the enclosing NSManagedObjectModel.
    public var objectInfo : ObjectInfo?
      {
        get { (objc_getAssociatedObject(self, &objectInfoKey) as? Boxed<ObjectInfo>)?.value }

        set {
          let associatedObject : Boxed<ObjectInfo>?
          switch newValue {
            case .some(let objectInfo) :
              associatedObject = Boxed(value: objectInfo)
            case .none :
              associatedObject = nil
          }
          objc_setAssociatedObject(self, &objectInfoKey, associatedObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
      }
  }
