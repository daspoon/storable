/*

*/

import Foundation


public final class BoxedValueTransformer<Value: Codable> : ValueTransformer
  {
    public override class func transformedValueClass() -> AnyClass
      { Boxed<Value>.self }

    public override class func allowsReverseTransformation() -> Bool
      { true }

    public override func transformedValue(_ any: Any?) -> Any?
      {
        guard let boxed = any as? Boxed<Value> else {
          log("failed to interpret argument as Boxed<\(Value.self)>: \(String(describing: any))")
          return nil
        }
        do {
          return try JSONEncoder().encode(boxed.value)
        }
        catch let error {
          log("failed to encode \(Value.self) as JSON data: \(error)")
          return nil
        }
      }

    public override func reverseTransformedValue(_ any: Any?) -> Any?
      {
        guard let data = any as? Data else {
          log("failed to interpret argument as Data: \(String(describing: any))")
          return nil
        }
        do {
          return Boxed(value: try JSONDecoder().decode(Value.self, from: data))
        }
        catch let error {
          log("failed to decode \(Value.self) from JSON data: \(error)")
          return nil
        }
      }
  }
