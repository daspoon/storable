/*

*/


/// IngestKey determines how an object property value is extracted from the IngestData provided on initialization.
///
public enum IngestKey : Equatable
  {
    /// The property value is the key component of the dictionary entry represented by the ingest data.
    case key

    /// The property value is the index of the array element represented by the ingest data.
    case index

    /// The property value is the the associated value of the ingest data.
    case value

    /// The data value is a dictionary and the property value is the named element of that dictionary.
    case element(String)

    /// The property value is not ingested.
    case ignore
  }


extension IngestKey : CustomStringConvertible
  {
    public var description : String
      {
        switch self {
          case .key : return "key"
          case .index : return "index"
          case .value : return "value"
          case .element(let name) : return "element(\"" + name + "\")"
          case .ignore : return "ignore"
        }
      }
  }


extension IngestKey : ExpressibleByStringLiteral
  {
    public init(stringLiteral name: String)
      { self = .element(name) }
  }


extension IngestKey
  {
    /// Attempt to convert a JSON value, which must be either a String or nil, to an IngestKey. A nil argument indicates the ingestKey is unspecified and so defaults
    /// to .element(name),  meaning we ingest the property using its name.
    init(with json: Any?, for propertyName: String) throws
      {
        if let json {
          guard let string = json as? String else { throw Exception("expecting string value or null") }
          switch string {
            case ".key" :
              self = .key
            case ".index" :
              self = .index
            case ".value" :
              self = .value
            case ".ignore" :
              self = .ignore
            default :
              self = .element(string)
          }
        }
        else {
          self = .element(propertyName)
        }
      }
  }
