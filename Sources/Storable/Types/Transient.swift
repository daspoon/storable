/*

  Created by David Spooner

*/

import CoreData


public struct Transient
  {
    public var name : String
    public var type : Any.Type
    public var isOptional : Bool
    public var defaultValue : Any?

    private init(name: String, type: Any.Type, isOptional: Bool, defaultValue: Any?)
      {
        self.name = name
        self.type = type
        self.isOptional = isOptional
        self.defaultValue = defaultValue
      }

    public init<T>(name: String, type: T.Type, defaultValue v: Any? = nil)
      { self.init(name: name, type: type, isOptional: false, defaultValue: v) }

    public init<T: Nullable>(name: String, type: T.Type, defaultValue v: Any? = nil)
      { self.init(name: name, type: type, isOptional: true, defaultValue: v) }
  }
