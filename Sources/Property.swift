/*

*/

import Foundation


public protocol Property
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// The means by which property values are established on object ingestion. Required.
    var ingestAction : IngestAction { get }

    /// Indicates whether or not the persisted value can be nil. Required.
    var allowsNilValue : Bool { get }
  }
