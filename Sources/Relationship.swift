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

    /// The key used to extract the ingested value from the info dictionary provided on object initialization.
    public let ingestKey : IngestKey

    /// The ingestMode determines how the related objects are obtained from the ingested value: 'reference' indicates the ingested value is the name of an independently created object, and  'create' indicates the ingested value is the JSON data required to create the related object(s).
    public let ingestMode : IngestMode

    /// The name of the related entity.
    public let relatedEntityName : String

    /// The name of the inverse relationship on the destination entity.
    public let inverseName : String

    /// The the arity of the inverse relationship on the destination entity.
    public let inverseArity : Arity

    /// The effect which deleting the related object has on the host object.
    public let inverseDeleteRule : DeleteRule


    /// Initialize a new instance.
    public init(name: String, arity: Arity, ingestKey: IngestKey, ingestMode: IngestMode, ingestName: String? = nil, deleteRule: DeleteRule, relatedEntityName: String, inverseName: String, inverseArity: Arity, inverseDeleteRule: DeleteRule)
      {
        self.name = name
        self.arity = arity
        self.ingestMode = ingestMode
        self.ingestKey = ingestKey
        self.deleteRule = deleteRule
        self.relatedEntityName = relatedEntityName
        self.inverseName = inverseName
        self.inverseArity = inverseArity
        self.inverseDeleteRule = inverseDeleteRule
      }


    public init(name: String, info: [String: Any]) throws
      {
        self.name = name

        // The arity, related entity name and inverse name are required.
        arity = try info.requiredValue(for: "arity")
        relatedEntityName = try info.requiredValue(for: "relatedType")
        inverseName = try info.requiredValue(for: "inverseName")

        // The default ingest key is the relation name.
        ingestKey = try info.optionalValue(for: "ingestKey") ?? .element(name)

        // The default delete rule depends on the arity.
        switch (try info.optionalValue(of: DeleteRule.self, for: "deleteRule"), arity) {
          case (.some(let r), _) : deleteRule = r
          case (.none, .toOne) : deleteRule = .nullify
          case (.none, .toMany) : deleteRule = .cascade
          case (.none, .optionalToOne) : deleteRule = .nullify
        }

        // The default ingest mode depends on the arity.
        switch (try info.optionalValue(of: IngestMode.self, for: "ingestMode"), arity) {
          case (.some(let m), _) : ingestMode = m
          case (.none, .toOne) : ingestMode = .reference
          case (.none, .toMany) : ingestMode = .create
          case (.none, .optionalToOne) : ingestMode = .reference
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


    public func generateSwiftText(for modelName: String) -> String
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
