/*

*/

import Foundation


public protocol PropertySpec
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Return the text used to declare the property in the Swift class definition.
    func generatePropertyDeclaration() -> String

    /// Return the text used to define the property in the Swift schema definition.
    func generatePropertyDefinition() -> String?
  }


extension PropertySpec
  {
    /// Used to implement generatePropertyDefinition, given the name of the constructed type and a list of optional key/value argument pairs.
    public func generateConstructor(_ typeName: String, argumentPairs: [(name: String?, value: String)?]) -> String
      {
        let specifiedArgumentPairs = argumentPairs.compactMap {$0}
        let specifiedArguments = specifiedArgumentPairs.map { (($0.map {$0 + ": "}) ?? "") + $1 }
        return typeName + "(" + specifiedArguments.joined(separator: ", ") + ")"
      }
  }
