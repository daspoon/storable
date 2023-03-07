/*

  Created by David Spooner

*/

import Foundation
import Storable


/// Act like a Bundle for the purpose of testing, mapping resource names to json data objects.

struct MockBundle : DataBundle
  {
    let resourceData : [String: Data]

    init(resources: [String: Any])
      {
        resourceData = resources.mapValues { try JSONEncoder().encode($0) }
      }

    public func jsonData(for name: String) throws -> Data
      {
        guard let data = resourceData[name] else { throw Exception("unknown resource name '\(name)'") }
        return data
      }
  }
