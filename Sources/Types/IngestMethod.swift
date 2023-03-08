/*

  Created by David Spooner

*/


/// An IngestMethod creates managed object instances from JSON data taken from an IngestSource.

public protocol IngestMethod
  {
    /// The name of the resource for logging purposes.
    var resourceName : String { get }

    /// A dot-separated key path identifying the required data as a component of a bundle resource; the first path element specifies the name of the resource, and subsequent elements are treated as dictionary keys (meaning the bundle resource is a dictionary). Returning nil indicates no data is required and thus the first argument of ingest(:into:) is arbitrary.
    var resourceKeyPath : String? { get }

    /// Create objects from the JSON resource data.
    func ingest(_ json: Any, into context: IngestContext) throws
  }
