/*

  Created by David Spooner

*/

import Foundation


/// An IngestSource provides a means to retrieve JSON resources by name; it abstracts the functionality of Foundation's Bundle for the purposes of this package.

public protocol IngestSource
  {
    /// Return the JSON data for the given resource name.
    func jsonData(for resourceName: String) throws -> Data
  }
