/*

  Created by David Spooner.

*/

#if os(macOS)

import AppKit
import UniformTypeIdentifiers


extension NSImage
  {
    public func pngData() -> Data?
      {
        // adapted from https://stackoverflow.com/a/68999948
        guard
          let data = CFDataCreateMutable(kCFAllocatorNull, 0),
          let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil),
          let cgimage = cgImage(forProposedRect: nil, context: nil, hints: nil)
        else { return nil }

        CGImageDestinationAddImage(destination, cgimage, nil)

        return CGImageDestinationFinalize(destination) ? data as Data : nil
      }
  }

#endif
