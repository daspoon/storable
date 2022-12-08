/*

*/


/// IngestData is the format of the data provided on object ingestion: it is a pair containing an optional name and a json value, where the name is non-nil iff the object is defined in the context of a dictionary.
public struct IngestData
  {
    /// The dictionary key associted with the json data.
    public let key : String?

    /// The specified json data.
    public let value : Any


    public init(key k: String? = nil, value v: Any)
      {
        key = k
        value = v
      }


    /// Extract the property value for a given key.
    public subscript (_ ingestKey: IngestKey) -> Any?
      {
        switch ingestKey {
          case .key :
            return key
          case .value :
            return value
          case .element(let name) :
            guard let dict = value as? [String: Any] else { return nil }
            return dict[name]
          case .ignore :
            return nil
        }
      }
  }
