/*

*/


@dynamicMemberLookup
public struct RelationshipSpec : PropertySpec
  {
    let relationship : Relationship
    let isInverse : Bool


    public init(inverseOf other: RelationshipSpec, on entity: EntitySpec)
      {
        relationship = other.relationship.inverse(for: entity.name)
        isInverse = true
      }


    public init(name: String, info: [String: Any]) throws
      {
        // The arity, related entity name and inverse name are required.

        let arity = try info.requiredValue(of: Relationship.Arity.self, for: "arity")
        let deleteRule = try info.optionalValue(of: Relationship.DeleteRule.self, for: "deleteRule") ?? .defaultValue(for: arity)
        let relatedEntityName = try info.requiredValue(of: String.self, for: "relatedType")
        let inverseName = try info.requiredValue(of: String.self, for: "inverseName")
        let inverseArity = try info.optionalValue(of: Relationship.Arity.self, for: "inverseArity") ?? .defaultInverseValue(for: arity)
        let inverseDeleteRule = try info.optionalValue(of: Relationship.DeleteRule.self, for: "inverseDeleteRule") ?? .defaultInverseValue(for: arity)
        let ingestKey = try IngestKey(with: info["ingestKey"], for: name)
        let ingestMode = try info.optionalValue(of: Relationship.IngestMode.self, for: "ingestMode") ?? .defaultValue(for: arity)

        relationship = .init(name,
          arity: arity,
          relatedEntityName: relatedEntityName,
          inverseName: inverseName,
          deleteRule: deleteRule,
          inverseArity: inverseArity,
          inverseDeleteRule: inverseDeleteRule,
          ingestKey: ingestKey,
          ingestMode: ingestMode
        )
        isInverse = false
      }


    public subscript <Value>(dynamicMember path: KeyPath<Relationship, Value>) -> Value
      { relationship[keyPath: path] }


    public var name : String
      { relationship.name }


    public func codegenPropertyDeclaration() -> String
      {
        let typeString : String
        switch self.arity {
          case .toOne : typeString = self.relatedEntityName
          case .toMany : typeString = "Set<" + self.relatedEntityName + ">"
          case .optionalToOne : typeString = self.relatedEntityName + "?"
        }
        return "@NSManaged var \(self.name) : \(typeString)"
      }


    public func codegenPropertyValue() -> String?
      {
        guard isInverse == false else { return nil }
        return codegenConstructor("Relationship", argumentPairs: [
          (nil, "\"" + self.name + "\""),
          ("arity", ".\(self.arity)"),
          ("relatedEntityName", "\"\(self.relatedEntityName)\""),
          ("inverseName", "\"\(self.inverseName)\""),
          ("deleteRule", ".\(self.deleteRule)"),
          ("inverseArity", ".\(self.inverseArity)"),
          ("inverseDeleteRule", ".\(self.inverseDeleteRule)"),
          ("ingestKey", ".\(self.ingestKey)"),
          ("ingestMode", ".\(self.ingestMode)"),
        ])
      }
  }
