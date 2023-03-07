/*

  Created by David Spooner

*/

import Foundation
import Storable


/// Act like a Bundle for the purpose of testing DataSource et.al., mapping resource names to subpaths of the 'resourcePath' specified in the launch arguments.

public struct MockBundle : DataBundle
  {
    let resourcePath : String


    public init() throws
      {
        guard let resourcePathArg = ProcessInfo.processInfo.arguments.first(where: {$0.hasPrefix("resourcePath=")}) else {
          throw Exception("missing argument value for 'resourcePath'")
        }
        resourcePath = resourcePathArg.removing(prefix: "resourcePath=")
      }


    // DataBundle

    public func url(forResource resourceName: String?, withExtension fileExtension: String?) -> URL?
      {
        var absolutePath = resourcePath
        if let resourceName {
          absolutePath = (absolutePath as NSString).appendingPathComponent(resourceName)
        }
        if let fileExtension {
          absolutePath = (absolutePath as NSString).appendingPathExtension(fileExtension)!
        }
        return URL(fileURLWithPath: absolutePath)
      }
  }
