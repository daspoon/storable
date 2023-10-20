/*

*/

#if os(macOS)
import AppKit
public typealias OSImage = NSImage
#elseif os(iOS)
import UIKit
public typealias OSImage = UIImage
#endif
