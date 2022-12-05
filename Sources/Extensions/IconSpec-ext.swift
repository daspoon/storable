/*

*/

import UIKit
import Schema


extension IconSpec
  {
    public var icon : UIImage
      {
        let image : UIImage?
        switch source {
          case .system :
            image = UIImage(systemName: name)
          case .bundle :
            image = UIImage(named: name)
        }
        return image ?? UIImage()
      }
  }

