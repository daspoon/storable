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

    /// The name of the attribute in the previous entity version, if necessary.
    public var renamingIdentifier : String?


    /// Initialize a new instance.
    private init<Value: Storable>(name: String, type: Value.Type, isOptional: Bool, defaultValue: Value?, renamingIdentifier: String?)
      {
        self.name = name
        self.type = type
        self.attributeType = Value.EncodingType.typeId
        self.valueTransformerName = Value.valueTransformerName
        self.defaultValue = defaultValue
        self.isOptional = isOptional
        self.renamingIdentifier = renamingIdentifier
      }


    /// Declare a non-optional attribute.
    public init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil, renamingIdentifier id: String? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v, renamingIdentifier: id) }


    /// Declare an optional attribute.
    public init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil, renamingIdentifier id: String? = nil) where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v, renamingIdentifier: id) }


    /// Return a copy of the receiver with changes made by the given code block.
    public func copy(withModifier method: (inout Self) -> Void) -> Self
      {
        var copy = self
        method(&copy)
        return copy
      }
  }


// MARK: --

/// The Attribute macro applied to member variables of a managed object subclass generates instances of the Attribute struct.
/// Note that a separate macro definition is required for each combination of optional parameter to corresponding init method of struct Attribute.

@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute(renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")


// MARK: --

extension Attribute : Diffable
  {
    /// Changes which affect the version hash of the generated NSAttributeDescription.
    public enum Change : Hashable
      {
        case name
        case isOptional
        case type
        //case isTransient(Bool, Bool)
      }

    public func difference(from old: Self) throws -> Set<Change>?
      {
        let changes : [Change] = [
          old.name != self.name ? .name : nil,
          old.isOptional != self.isOptional ? .isOptional : nil,
          old.type != self.type ? .type : nil,
        ].compactMap {$0}
        return changes.count > 0 ? Set(changes) : nil
      }
  }
