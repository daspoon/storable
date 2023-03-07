/*

  Created by David Spooner

  Extensions to CoreData classes for the convenience of writing test cases.

*/

import CoreData


/// Enable common treatment of entity and property descriptor classes.
protocol ObjectModelComponent : NSObject
  { var versionHash : Data { get } }


extension NSPropertyDescription : ObjectModelComponent
  {}


extension NSAttributeDescription
  {
    convenience init(name: String, type: AttributeType = .string, _ customize: ((NSAttributeDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        self.type = type
        customize?(self)
      }
  }

extension NSFetchedPropertyDescription
  {
    convenience init(name: String, _ customize: ((NSFetchedPropertyDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSRelationshipDescription
  {
    convenience init(name: String, _ customize: ((NSRelationshipDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSEntityDescription : ObjectModelComponent
  {
    convenience init(name: String, _ customize: ((NSEntityDescription) -> Void)? = nil)
      {
        self.init()
        self.name = name
        customize?(self)
      }
  }

extension NSManagedObjectModel
  {
    convenience init(entities: [NSEntityDescription])
      {
        self.init()
        self.entities = entities
      }
  }
