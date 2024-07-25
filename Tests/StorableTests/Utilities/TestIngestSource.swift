/*

  Created by David Spooner

*/

import Foundation
@testable import Storable


/// An IngestSource for testing purposes. Initialized with a mapping of resource names to JSON values.

struct TestIngestSource : IngestSource
  {
    let resourceData : [String: Data]

    init(resources: [String: Any]) throws
      {
        resourceData = Dictionary(uniqueKeysWithValues: try resources.map { (key, value) in
          return (key, try JSONSerialization.data(withJSONObject: value))
        })
      }

    public func jsonData(for name: String) throws -> Data
      {
        guard let data = resourceData[name] else { throw Exception("unknown resource name '\(name)'") }
        return data
      }
  }
