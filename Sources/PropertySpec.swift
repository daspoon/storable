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
