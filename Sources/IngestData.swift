/*

*/


/// IngestData is the format of the data provided on object ingestion: it is a pair containing an optional name and a json value, where the name is non-nil iff the object is defined in the context of a dictionary.
public struct IngestData
  {
    /// The dictionary key associted with the json data.
    public let name : String?

    /// The specified json data.
    public let json : Any


    public init(key: String? = nil, value: Any)
      {
        name = key
        json = value
      }


    /// Extract the property value for a given key.
    public subscript (_ ingestKey: IngestKey) -> Any?
      {
        switch ingestKey {
          case .name :
            return name
          case .value :
            return json
          case .element(let key) :
            guard let dict = json as? [String: Any] else { return nil }
            return dict[key]
          case .none :
            preconditionFailure("unexpected case")
        }
      }
  }
