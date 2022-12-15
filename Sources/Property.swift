/*

*/

import Foundation


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates how the associated value is obtained from object ingest data. Required.
    var ingestKey : IngestKey { get }

    /// The default value to be persisted when no value is provided on ingest. Required.
    var defaultIngestValue : (any Storable)? { get }

    /// Indicates whether or not the persisted value can be nil. Required.
    var allowsNilValue : Bool { get }
  }
