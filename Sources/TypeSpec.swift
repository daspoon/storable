/*

*/


public protocol TypeSpec
  {
    associatedtype Input

    var name : String { get }
    var swiftText : String { get }

    init(name: String, json: Input, in environment: [String: any TypeSpec]) throws
  }
