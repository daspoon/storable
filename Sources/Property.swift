/*

*/

import Foundation


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates whether or not the property value is ingested. Required.
    var ingested : Bool { get }

    /// Indicates whether or not a property value is required on ingest. Required.
    var optional : Bool { get }

    /// The ingestion method translates a JSON value  into an object value supported by CoreData, and must be implemented if ingested returns true. The default implementation causes a fatal error.
    func ingest(json: Any) throws -> NSObject
  }


extension Property
  {
    func ingest(json: Any) throws -> NSObject
      { fatalError("required when ingested is true") }
  }
