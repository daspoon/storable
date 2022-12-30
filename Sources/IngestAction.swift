/*

*/


/// IngestAction determines how the value of a managed property is established on object initialization.
///
public enum IngestAction
  {
    /// The value is extracted from the ingest data.
    case ingest(key: IngestKey, defaultValue: (any Storable)? = nil)

    /// The value is a constant associated with the property.
    case initialize(initialValue: (any Storable)?)

    /// The value is established implicitly (e.g. an inverse relationship).
    case ignore
  }
