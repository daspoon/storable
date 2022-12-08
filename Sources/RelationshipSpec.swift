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

        let arity : Relationship.Arity = try info.requiredValue(for: "arity")

        relationship = .init(
          name: name,
          arity: arity,
          deleteRule: try Self.deleteRule(from: info, arity: arity),
          relatedEntityName: try info.requiredValue(for: "relatedType"),
          inverseName: try info.requiredValue(for: "inverseName"),
          inverseArity: try Self.inverseArity(from: info, arity: arity),
          inverseDeleteRule: try Self.inverseDeleteRule(from: info, arity: arity),
          ingestInfo: try Self.ingestInfo(from: info, arity: arity)
        )
      }


    static func deleteRule(from info: [String: Any], arity: Relationship.Arity) throws -> Relationship.DeleteRule
      {
        // The default delete rule depends on the arity.
        switch (try info.optionalValue(of: Relationship.DeleteRule.self, for: "deleteRule"), arity) {
          case (.some(let r), _) : return r
          case (.none, .toOne) : return .nullify
          case (.none, .toMany) : return .cascade
          case (.none, .optionalToOne) : return .nullify
        }
      }

    static func inverseArity(from info: [String: Any], arity: Relationship.Arity) throws -> Relationship.Arity
      {
        // The default inverse arity depends on the arity.
        switch (try info.optionalValue(of: Relationship.Arity.self, for: "inverseArity"), arity) {
          case (.some(let a), _) : return a
          case (.none, .toOne) : return .toMany
          case (.none, .toMany) : return .toOne
          case (.none, .optionalToOne) : return .optionalToOne
        }
      }

    static func inverseDeleteRule(from info: [String: Any], arity: Relationship.Arity) throws -> Relationship.DeleteRule
      {
        // The default inverse delete rule depends on the arity (TODO: review...)
        switch (try info.optionalValue(of: Relationship.DeleteRule.self, for: "inverseDeleteRule"), arity) {
          case (.some(let r), _) : return r
          case (.none, .toOne) : return .cascade
          case (.none, .toMany) : return .nullify
          case (.none, .optionalToOne) : return .nullify
        }
      }

    static func ingestInfo(from info: [String: Any], arity: Relationship.Arity) throws -> Relationship.IngestInfo?
      {
        // The default ingest key is the relation name, but the default mode depends on the arity.
        if let key = try IngestKey(with: info["ingestKey"], for: "name") {
          switch (try info.optionalValue(of: Relationship.IngestMode.self, for: "ingestMode"), arity) {
            case (.some(let mode), _) :
              return (key, mode)
            case (.none, .toMany) :
              return (key, .create)
            case (.none, .toOne), (.none, .optionalToOne) :
              return (key, .reference)
          }
        }
        else {
          return nil
        }
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


    public func generateSwiftIngestDescriptor() -> String?
      {
        guard let ingestInfo = relationship.ingestInfo else { return nil }
        return ".init(\"\(relationship.name)\", ingestKey: \(ingestInfo.key.swiftText), ingestAction: .relate(relatedEntityName: \"\(relationship.relatedEntityName)\", arity: .\(relationship.arity.rawValue), ingestMode: .\(ingestInfo.mode.rawValue)), optional: \(relationship.optional))"
      }
  }
