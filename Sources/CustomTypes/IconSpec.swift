/*

*/

import UIKit
import Schema


public struct IconSpec : Ingestible
  {
    public enum Source : String { case system, bundle }

    public let name : String
    public let source : Source
    public let tintColor : UIColor

    public init(name: String, source: Source, tintColor: UIColor)
      {
        self.name = name
        self.source = source
        self.tintColor = tintColor
      }

    public init(json dict: [String: Any]) throws
      {
        name = try dict.requiredValue(for: "name")
        source = try dict.requiredValue(for: "source")
        tintColor = try dict.requiredValue(for: "tintColor")
      }

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
