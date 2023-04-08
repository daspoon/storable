/*

*/

#if os(macOS)
import AppKit
public typealias OSImage = NSImage
#elseif os(iOS)
import UIKit
public typealias OSImage = UIImage
#endif

import CoreData


#if os(macOS) || os(iOS)

extension OSImage : StorageType
  {
    public static var typeId : NSAttributeDescription.AttributeType
      { .transformable }

    public static var valueTransformerName : NSValueTransformerName?
      { .imageValueTransformerName() }
  }

#endif
