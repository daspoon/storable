/*

*/


/// Represents a relation between entities.  Note that every relationship has an inverse, but only one endpoint is specified explicitly.
public struct Relationship : Property
  {
    public enum Arity : String, Ingestible { case toOne, optionalToOne, toMany }
    public enum DeleteRule : String, Ingestible { case cascade, nullify }
    public enum IngestMode : String, Ingestible { case reference, create }


    /// The name of the corresponding property of the source entity.
    public let name : String

    /// The arity indicates the potential number of related objects.
    public let arity : Arity

    /// The effect which deleting the host object has on the related object.
    public let deleteRule : DeleteRule

    /// The name of the related entity.
    public let relatedEntityName : String

    /// The name of the inverse relationship on the destination entity.
    public let inverseName : String

    /// The the arity of the inverse relationship on the destination entity.
    public let inverseArity : Arity

    /// The effect which deleting the related object has on the host object.
    public let inverseDeleteRule : DeleteRule

    /// Determines how related objects are obtained from the ingest value, if any, provided on object initialization: a mode of 'reference' indicates that ingested values name existing objects;
    /// a mode of 'create' indicates ingested values are JSON data used to create the related objects. Nil indicates the relation is not ingested.
    public let ingest: (key: IngestKey, mode: IngestMode)?


    /// Initialize a new instance.
    public init(name: String, arity: Arity, deleteRule: DeleteRule, relatedEntityName: String, inverseName: String, inverseArity: Arity, inverseDeleteRule: DeleteRule, ingest: (key: IngestKey, mode: IngestMode)?)
      {
        self.name = name
        self.arity = arity
        self.deleteRule = deleteRule
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.inverseArity = inverseArity
        self.inverseDeleteRule = inverseDeleteRule
        self.ingest = ingest
      }


    public init(name: String, info: [String: Any]) throws
      {
        self.name = name

        // The arity, related entity name and inverse name are required.
        arity = try info.requiredValue(for: "arity")
        relatedEntityName = try info.requiredValue(for: "relatedType")
        inverseName = try info.requiredValue(for: "inverseName")

        // The default delete rule depends on the arity.
        switch (try info.optionalValue(of: DeleteRule.self, for: "deleteRule"), arity) {
          case (.some(let r), _) : deleteRule = r
          case (.none, .toOne) : deleteRule = .nullify
          case (.none, .toMany) : deleteRule = .cascade
          case (.none, .optionalToOne) : deleteRule = .nullify
        }

        // The default inverse arity depends on the arity.
        switch (try info.optionalValue(of: Arity.self, for: "inverseArity"), arity) {
          case (.some(let a), _) : inverseArity = a
          case (.none, .toOne) : inverseArity = .toMany
          case (.none, .toMany) : inverseArity = .toOne
          case (.none, .optionalToOne) : inverseArity = .optionalToOne
        }

        // The default inverse delete rule depends on the arity (TODO: review...)
        switch (try info.optionalValue(of: DeleteRule.self, for: "inverseDeleteRule"), arity) {
          case (.some(let r), _) : inverseDeleteRule = r
          case (.none, .toOne) : inverseDeleteRule = .cascade
          case (.none, .toMany) : inverseDeleteRule = .nullify
          case (.none, .optionalToOne) : inverseDeleteRule = .nullify
        }

        // The default ingest key is the relation name, but the default mode depends on the arity.
        if let key = try IngestKey(with: info["ingestKey"], for: "name") {
          switch (try info.optionalValue(of: IngestMode.self, for: "ingestMode"), arity) {
            case (.some(let mode), _) :
              ingest = (key, mode)
            case (.none, .toMany) :
              ingest = (key, .create)
            case (.none, .toOne), (.none, .optionalToOne) :
              ingest = (key, .reference)
          }
        }
        else {
          ingest = nil
        }
      }


    public var optional : Bool
      {
        switch arity {
          case .optionalToOne, .toMany :
            return true
          case .toOne :
            return false
        }
      }


    public func generateSwiftDeclaration() -> String
      {
        """
        @NSManaged var \(name) : \({
          switch arity {
            case .toOne : return relatedEntityName
            case .toMany : return "Set<" + relatedEntityName + ">"
            case .optionalToOne : return relatedEntityName + "?"
          }
        }())
        """
      }


    public func generateSwiftIngestDescriptor() -> String?
      {
        guard let ingest else { return nil }
        return ".init(\"\(name)\", ingestKey: \(ingest.key.swiftText), ingestAction: .relate(relatedEntityName: \"\(relatedEntityName)\", arity: .\(arity.rawValue), ingestMode: .\(ingest.mode.rawValue)), optional: \(optional))"
      }
  }


extension Relationship.Arity
  {
    var rangeOfCount : ClosedRange<Int>
      {
        switch self {
          case .optionalToOne :
            return 0 ... 1
          case .toOne :
            return 1 ... 1
          case .toMany :
            return 0 ... .max
        }
      }
  }
