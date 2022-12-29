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


extension IngestKey : ExpressibleByStringLiteral
  {
    public init(stringLiteral name: String)
      { self = .element(name) }
  }
