/*

*/

import CoreData


@propertyWrapper
public struct ToManyRelationship<Value: Object> : ManagedPropertyWrapper
  {
    public let property : Property


    public init(_ propertyName: String, inverseName: String, deleteRule: NSDeleteRule? = nil)
      {
        property = Relationship(propertyName, arity: .toMany, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: deleteRule)
      }


//    @available(*, unavailable, message: "Accessible only as a property on an NSManagedObject")
    public var wrappedValue : Set<Value> { get { fatalError() } set { fatalError() } }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Owner: Object>(_enclosingInstance: Owner, wrapped: ReferenceWritableKeyPath<Owner, Set<Value>>, storage: ReferenceWritableKeyPath<Owner, Self>) -> Set<Value>
      {
        get {
          let wrapper = _enclosingInstance[keyPath: storage]
          do {
            switch _enclosingInstance.primitiveValue(forKey: wrapper.property.name) {
              case .some(let set) :
                return try throwingCast(set, as: Set<Value>.self)
              case .none :
                return []
            }
          }
          catch let error as NSError {
            fatalError("failed to get value of type \(Value.self) for property '\(wrapper.property.name)': \(error)")
          }
        }
        set {
          let wrapper = _enclosingInstance[keyPath: storage]
          _enclosingInstance.setPrimitiveValue(newValue, forKey: wrapper.property.name)
        }
      }
  }
