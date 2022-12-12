/*

*/


public protocol TypeSpec
  {
    associatedtype Input

    var name : String { get }

    init(name: String, json: Input, in environment: [String: any TypeSpec]) throws

    func codegenTypeDefinition(for modelName: String) -> String
  }
