/*

*/

import CoreData


public func log(_ message: @autoclosure () -> String, function: String = #function)
  { print("--- \(function) - \(message())") }


public func sign<T: BinaryInteger>(_ i: T) -> T
  { i < 0 ? -1 : 1 }


func throwingCast<T>(_ v: Any, as: T.Type = T.self) throws -> T
  {
    guard let t = v as? T else { throw Exception("expecting value of type \(T.self)") }
    return t
  }
