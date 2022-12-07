/*

*/


/// IngestKey is the means of specifying how property values are extracted from object ingest data.
public enum IngestKey
  {
    /// The property value is the name component of the data.
    case name

    /// The property value is the value component of the data.
    case value

    /// The data value is a dictionary and the property value is the specified element of that dictionary.
    case element(String)
  }


extension IngestKey : CustomStringConvertible
  {
    public var description : String
      {
        switch self {
          case .name : return "<name>"
          case .value : return "<value>"
          case .element(let key) : return key
        }
      }
  }


extension IngestKey
  {
    /// Attempt to convert a JSON value, which must be either a String or nil, to an IngestKey. A nil argument indicates the ingestKey is unspecified and so defaults
    /// to .element(name),  meaning we ingest the property using its name;  a "<none>" argument indicates the ingestKey is nil, meaning the property is not ingested.
    init?(with json: Any?, for propertyName: String) throws
      {
        if let json {
          guard let string = json as? String else { throw Exception("expecting string value or null") }
          switch string {
            case "<none>" :
              return nil
            case "<name>" :
              self = .name
            case "<value>" :
              self = .value
            default :
              self = .element(string)
          }
        }
        else {
          self = .element(propertyName)
        }
      }

    var swiftText : String
      {
        switch self {
          case .name : return ".name"
          case .value : return ".value"
          case .element(let key) : return ".element(\"\(key)\")"
        }
      }
  }
