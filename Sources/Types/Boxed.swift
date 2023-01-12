/*

*/

import Foundation


// Wrap a Codable type as an NSObject which implements NSSecureCoding, as is required of default values specified in an NSAttributeDescription.

public final class Boxed<Value: Codable> : NSObject, NSSecureCoding
  {
    public var value : Value

    public init(value v: Value)
      {
        value = v
      }

    // NSSecureCoding

    public static var supportsSecureCoding : Bool
      { true }

    public init?(coder: NSCoder)
      {
        guard let data = coder.decodeData() else {
          log("failed to decode data")
          return nil
        }
        guard let v = try? JSONDecoder().decode(Value.self, from: data) else {
          log("failed to decode \(Value.self) from JSON data")
          return nil
        }
        value = v
      }

    public func encode(with coder: NSCoder)
      {
        guard let data = try? JSONEncoder().encode(value) else {
          log("failed to encode \(Value.self) as JSON")
          return
        }
        coder.encode(data)
      }
  }
