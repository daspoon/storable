/*

*/

import Foundation


/// Abstracts the functionality of Bundle required by DataSource to simplify testing.
///
public protocol DataBundle
  {
    func url(forResource resourceName: String?, withExtension fileExtension: String?) -> URL?
  }


extension Bundle : DataBundle
  { }
