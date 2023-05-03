

extension IngestKey : Ingestible
  {
    public init(json: String) throws
      {
        switch (json.hasPrefix("."), json.removing(prefix: ".")) {
          case (false, _) : self.init(stringLiteral: json)
          case (true, "key") :   self = .key
          case (true, "index") : self = .index
          case (true, "value") : self = .value
          case (true, let other) :
            throw Exception("invalid value for IngestKey: \(other)")
        }
      }

    public var swiftText : String
      {
        switch self {
          case .element(let name) :
            return name
          default :
            return "\"\(self)\""
        }
      }
  }
