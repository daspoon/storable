/*

  Created by David Spooner

*/

import CoreData


/// The Attribute struct maintains defines an attribute on a class of managed object; it is analogous to CoreData's NSAttributeDescription.

public struct Attribute
  {
    /// The managed property name.
    public var name : String

    /// The Storable value type provided on initialization.
    public var type : Any.Type

    /// The CoreData attribute storage type..
    public var attributeType : NSAttributeDescription.AttributeType

    /// Non-nil when attributeType is 'transformable'
    public var valueTransformerName : NSValueTransformerName?

    /// The optional default value.
    public var defaultValue : (any Storable)?

    /// Indicates whether or not nil is an legitimate property value.
    public var isOptional : Bool


    /// Initialize a new instance.
    private init<Value: Storable>(name: String, type: Value.Type, isOptional: Bool, defaultValue: Value?)
      {
        self.name = name
        self.type = type
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.isOptional = isOptional
      }


    /// Declare a non-optional attribute.
    public init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v) }

    /// Declare an optional attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil) where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v) }
  }


// MARK: --

/// The Attribute macro applied to member variables of a managed object subclass generates instances of the Attribute struct.

@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
