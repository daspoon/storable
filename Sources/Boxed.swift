/*

*/

import Foundation


public final class Boxed<Value> : NSObject
  {
    public var value : Value

    public init(value v: Value)
      {
        value = v
      }
  }
