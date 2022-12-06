/*

*/


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates whether or not a property value is required on ingest. Required.
    var optional : Bool { get }

    /// The key used to extract the property value from the ingest data provided on object initialization, with nil indicating the property is not assigned on ingestion. Required.
    var ingestKey : IngestKey? { get }
  }
