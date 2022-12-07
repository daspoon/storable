/*

*/


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates whether or not a property value is required on ingest. Required.
    var optional : Bool { get }

    /// Return the Swift source used to declare the property.
    func generateSwiftDeclaration() -> String

    /// Return the Swift source used to create the property ingest descriptor, iff the property is ingested.
    func generateSwiftIngestDescriptor() -> String?
  }
