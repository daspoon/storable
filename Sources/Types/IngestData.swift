/*

*/


/// IngestData provides a common interface to the variably-structured json data provided on ingestion of Object instances. Property values are extracted from IngestData using IngestKeys.

public enum IngestData
  {
    /// The object ingest data is an arbitrary json value.
    case value(Any)
    
    /// The object ingest data is an array element with the given index.
    case arrayElement(index: Int, value: Any)

    /// The object ingest data is a dictionary entry with the given key and value.
    case dictionaryEntry(key: String, value: Any)


    /// Extract the associated value, stripped of possible array index or dictionary key.
    var value : Any
      {
        switch self {
          case .value(let value), .arrayElement(_, let value), .dictionaryEntry(_, let value) :
            return value
        }
      }


    /// Extract the property value for a given ingest key.
    public subscript (_ ingestKey: IngestKey) -> Any?
      {
        switch (ingestKey, self) {
          case (.value, _) : return self.value
          case (.key, .dictionaryEntry(let key, _)) : return key
          case (.index, .arrayElement(let index, _)) : return index
          case (.element(let name), _) :
            guard let dict = self.value as? [String: Any] else { return nil }
            return dict[name]
          default :
            return nil
        }
      }
  }
