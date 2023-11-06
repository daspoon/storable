/*

  Created by David Spooner

*/

import SwiftCompilerPlugin
import SwiftSyntaxMacros


@main
struct StorableMacroPlugin : CompilerPlugin
  {
    let providingMacros : [Macro.Type] = [
      AttributeMacro.self,
      EntityMacro.self,
      FetchedMacro.self,
      RelationshipMacro.self,
      TransientMacro.self,
    ]
  }
