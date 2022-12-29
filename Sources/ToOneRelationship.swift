/*

*/

import CoreData


@propertyWrapper
public struct ToOneRelationship<Value: Object> : ManagedPropertyWrapper
  {
    public let property : Property


    public init(_ propertyName: String, inverseName: String, deleteRule r: NSDeleteRule? = nil, ingestKey k: IngestKey? = nil, ingestMode m: Relationship.IngestMode? = nil)
      {
        property = Relationship(propertyName, arity: .toOne, relatedEntityName: Value.entityName, inverseName: inverseName, deleteRule: r, ingestKey: k, ingestMode: m)
      }


//    @available(*, unavailable, message: "Accessible only as a property on an NSManagedObject")
    public var wrappedValue : Value { get { fatalError() } set { fatalError() } }


    /// Retrieving the property value requires access to the enclosing object instance.
    public static subscript<Owner: Object>(_enclosingInstance: Owner, wrapped: ReferenceWritableKeyPath<Owner, Value>, storage: ReferenceWritableKeyPath<Owner, Self>) -> Value
      {
        get {
          let wrapper = _enclosingInstance[keyPath: storage]
          do {
            switch _enclosingInstance.primitiveValue(forKey: wrapper.property.name) {
              case .some(let object) :
                return try throwingCast(object, as: Value.self)
              case .none :
                throw Exception("no stored value for '\(wrapper.property.name)'")
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
