/*

  Created by David Spooner.

*/

import Foundation


extension Bundle : IngestSource
  {
    public func jsonData(for resourceName: String) throws -> Data
      {
        guard let url = url(forResource: resourceName, withExtension: "json") else {
          throw Exception("json file '\(resourceName)' not found in bundle")
        }

        let data : Data
        do {
          try data = Data(contentsOf: url)
        }
        catch let error as NSError {
          throw Exception("failed to load data from '\(url.lastPathComponent)': " + error.localizedDescription)
        }

        return data
      }
  }
