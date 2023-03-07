/*

  Created by David Spooner

*/

import Foundation


/// DataBundle abstracts the subset of Bundle functionality required by DataSource, primarily to simplify testing.

public protocol DataBundle
  {
    func jsonData(for resourceName: String) throws -> Data
  }
