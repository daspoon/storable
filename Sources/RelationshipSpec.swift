/*

*/


@dynamicMemberLookup
public struct RelationshipSpec : PropertySpec
  {
    let relationship : Relationship


    public init(relationship r: Relationship)
      {
        relationship = r
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
        let ingestKey = try IngestKey(with: info["ingestKey"], for: "name")
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
      }


    public subscript <Value>(dynamicMember path: KeyPath<Relationship, Value>) -> Value
      { relationship[keyPath: path] }


    public var name : String
      { relationship.name }


    public var optional : Bool
      { relationship.optional }


    public func generatePropertyDeclaration() -> String
      {
        """
        @NSManaged var \(relationship.name) : \({
          switch relationship.arity {
            case .toOne : return relationship.relatedEntityName
            case .toMany : return "Set<" + relationship.relatedEntityName + ">"
            case .optionalToOne : return relationship.relatedEntityName + "?"
          }
        }())
        """
      }


    public func generatePropertyDefinition() -> String
      {
        "Relationship(\"\(name)\", arity: .\(relationship.arity), relatedEntityName: \"\(relationship.relatedEntityName)\", inverseName: \"\(relationship.inverseName)\", deleteRule: .\(relationship.deleteRule), inverseArity: .\(relationship.inverseArity), inverseDeleteRule: .\(relationship.inverseDeleteRule), ingestKey: .\(relationship.ingestKey), ingestMode: .\(relationship.ingestMode))"
      }
  }
