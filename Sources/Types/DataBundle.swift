/*

*/

import Foundation


/// DataBundle abstracts the subset of Bundle functionality required by DataSource, primarily to simplify testing.

public protocol DataBundle
  {
    func url(forResource resourceName: String?, withExtension fileExtension: String?) -> URL?
  }


extension Bundle : DataBundle
  { }
