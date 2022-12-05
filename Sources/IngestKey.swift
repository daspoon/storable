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


extension IngestKey : Ingestible
  {
    public init(json string: String) throws
      {
        switch string {
          case "<name>" :
            self = .name
          case "<value>" :
            self = .value
          default :
            self = .element(string)
        }
      }
  }
