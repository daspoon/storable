/*

  Created by David Spooner

*/

import Foundation


fileprivate var registeredNames : Set<NSValueTransformerName> = []
fileprivate var registeredNamesSemaphore : DispatchSemaphore = .init(value: 1)


extension NSValueTransformerName
  {
    internal static func register<T: ValueTransformer>(_ type: T.Type, for string: String) -> NSValueTransformerName
      {
        let name = NSValueTransformerName(rawValue: string)
        registeredNamesSemaphore.wait()
        if registeredNames.contains(name) == false {
          ValueTransformer.setValueTransformer(type.init(), forName: name)
          registeredNames.insert(name)
        }
        registeredNamesSemaphore.signal()
        return name
      }

    /// Returns the name of a BoxedValueTransformer translateing between Codable type T and Data, creating and registering an instance if necessary.
    public static func boxedValueTransformerName<T>(for type: T.Type) -> NSValueTransformerName where T : Codable
      { register(BoxedValueTransformer<T>.self, for: "boxedValueTransformer<\(T.self)>") }
  }
