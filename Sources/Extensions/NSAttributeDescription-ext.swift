/*

*/

import CoreData


extension NSAttributeDescription
  {
    convenience init(name: String, type: AttributeType, isOptional: Bool)
      {
        self.init()
        self.name = name
        self.type = type
        self.isOptional = isOptional
      }
  }
