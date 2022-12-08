/*

*/

import Foundation


public protocol PropertySpec
  {
    /// The name of the model property. Required.
    var name : String { get }

    /// Indicates whether or not a property value is required on ingest. Required.
    var optional : Bool { get }

    /// Return the text used to declare the property in the Swift class definition.
    func generatePropertyDeclaration() -> String

    /// Return the text used to define the property in the Swift schema definition.
    func generatePropertyDefinition() -> String?
  }
