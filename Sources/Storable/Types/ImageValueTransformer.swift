/*

  Created by David Spooner

*/

#if os(macOS) || os(iOS)

import Foundation


class ImageValueTransformer : ValueTransformer
  {
    public override class func transformedValueClass() -> AnyClass
      { OSImage.self }

    public override class func allowsReverseTransformation() -> Bool
      { true }

    public override func transformedValue(_ any: Any?) -> Any?
      {
        guard let image = any as? OSImage else {
          log(level: .error, "failed to interpret argument as \(OSImage.self)>: \(String(describing: any))")
          return nil
        }
        guard let data = image.pngData() else {
          log(level: .error, "failed to extract PNG image data")
          return nil
        }
        return data
      }

    public override func reverseTransformedValue(_ any: Any?) -> Any?
      {
        guard let data = any as? Data else {
          log(level: .error, "failed to interpret argument as Data: \(String(describing: any))")
          return nil
        }
        return OSImage(data: data)
      }
  }
  

extension NSValueTransformerName
  {
    /// Returns the name of an ImageTransformer which translates between NS/UIImage and Data, creating and registering an instance if necessary.
    public static func imageValueTransformerName() -> NSValueTransformerName
      { register(ImageValueTransformer.self, for: "imageValueTransformer") }
  }

#endif
