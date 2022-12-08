/*

*/

import Foundation


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates whether or not the property value is ingested. Required.
    var ingestKey : IngestKey { get }

    /// Indicates whether or not a property value is required on ingest. Required.
    var optional : Bool { get }
  }
