/*

  Created by David Spooner

*/

import Foundation


/// Boxed<T> wraps a Codable type T as an NSObject which implements NSSecureCoding; it is used to implement transformable attributes of Codable type and to specify default values in NSAttributeDescription instances.

public final class Boxed<Value: Codable> : NSObject, NSSecureCoding, Codable
  {
    public var value : Value

    public init(value v: Value)
      {
        value = v
      }


    // Codable

    enum CodingKeys : CodingKey { case value }

    public init(from coder: Decoder) throws
      {
        let container = try coder.container(keyedBy: CodingKeys.self)
        value = try container.decode(Value.self, forKey: CodingKeys.value)
      }

    public func encode(to coder: Encoder) throws
      {
        var container = coder.container(keyedBy: CodingKeys.self)
        try container.encode(value, forKey: CodingKeys.value)
      }


    // NSSecureCoding

    public static var supportsSecureCoding : Bool
      { true }

    public init?(coder: NSCoder)
      {
        guard let data = coder.decodeData() else {
          log(level: .error, "failed to decode data")
          return nil
        }
        guard let v = try? JSONDecoder().decode(Value.self, from: data) else {
          log(level: .error, "failed to decode \(Value.self) from JSON")
          return nil
        }
        value = v
      }

    public func encode(with coder: NSCoder)
      {
        guard let data = try? JSONEncoder().encode(value) else {
          log(level: .error, "failed to encode \(Value.self) as JSON")
          return
        }
        coder.encode(data)
      }
  }
