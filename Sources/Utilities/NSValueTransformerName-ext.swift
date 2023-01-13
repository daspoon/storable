/*

*/

import Foundation


fileprivate var registeredNames : Set<NSValueTransformerName> = []


extension NSValueTransformerName
  {
    /// Returns the name of a BoxedValueTransform which translate between Codable type T and Data, creating and registering an instance if necessary.
    public static func boxedValueTransformerName<T>(for type: T.Type) -> NSValueTransformerName where T : Codable
      {
        let name = NSValueTransformerName(rawValue: "boxedValueTransformer<\(T.self)>")
        if registeredNames.contains(name) == false {
          ValueTransformer.setValueTransformer(BoxedValueTransformer<T>(), forName: name)
          registeredNames.insert(name)
        }
        return name
      }
  }
