/*

  Created by David Spooner

  Given the file path of a JSON array of entity descriptions, this program outputs Swift code for the corresponding ManagedObject class declarations.

*/

import Foundation
import StorableBase


let args = ProcessInfo.processInfo.arguments
guard args.count == 2
  else { throw Exception("usage: <inputPath>") }

guard let data = FileManager.default.contents(atPath: args[1])
  else { throw Exception("failed to read file '\(args[1])'") }

print(
  """
  /*

    Generated from \((args[1] as NSString).lastPathComponent) by \(ProcessInfo.processInfo.processName).

  */

  import Foundation
  import StorableBase

  """
)

for entityInfo in try JSONSerialization.jsonObject(of: [[String: Any]].self, from: data) {
  let className = try entityInfo.requiredValue(of: String.self, for: "name")
  let superclassName = try entityInfo.optionalValue(of: String.self, for: "superclass") ?? "ManagedObject"
  let propertyInfo = try entityInfo.optionalDictionaryValue(of: PropertySpec.self, for: "properties") ?? [:]

  print(
    """
    public class \(className) : \(superclassName) {
      public override class var declaredPropertiesByName : [String: Property] {
        return Dictionary(uniqueKeysWithValues: [
          \(propertyInfo.map({name, info in "(\"\(name)\", \(info.textForDescriptor(with: name)))"}).joined(separator: "," + .newline()).indented(6))
        ])
      }

      \(propertyInfo.flatMap({name, info in info.textArrayForDeclaration(with: name)}).joined(separator: .newline()).indented(2))
    }

    """
  )
}
