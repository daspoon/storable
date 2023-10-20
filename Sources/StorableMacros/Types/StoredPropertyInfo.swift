/*

  Created by David Spooner

*/

import SwiftSyntax


/// A convenience type aggregating the name, type and optional initial value of a variable declaration.
typealias StoredPropertyInfo = (name: String, type: TypeSyntax, value: ExprSyntax?)
