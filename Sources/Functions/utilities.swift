/*

*/

import Foundation


public func log(_ message: @autoclosure () -> String, function: String = #function)
  { print("--- \(function) - \(message())") }


public func sign<T: BinaryInteger>(_ i: T) -> T
  { i < 0 ? -1 : 1 }
