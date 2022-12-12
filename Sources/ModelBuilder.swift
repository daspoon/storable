/*

*/

import CoreData


public struct ModelBuilder
  {
    /// The name of the generated type.
    public let modelName : String

    /// The mapping of names to type specifications extracted from the input file.
    private var environment : [String: any TypeSpec] = [:]

    /// Initialize a new instance with the given name and configuration file path.
    public init(modelName name: String, inputPath: String) throws
      {
        modelName = name

        // Attempt to read the content at the given path
        guard let inputData = FileManager.default.contents(atPath: inputPath) else { throw Exception("failed to read file '\(inputPath)'") }

        // The content must be a json array of dictionaries representing type specifications
        let infoArray = try JSONSerialization.jsonObject(of: [[String: Any]].self, from: inputData)

        // Build the environment mapping names to type specifications from the input list.
        for info in infoArray {
          let name = try info.requiredValue(of: String.self, for: "name")
          guard environment[name] == nil else { throw Exception("multiple definition of '\(name)") }
          let kind = try info.requiredValue(of: String.self, for: "kind")
          let spec : any TypeSpec
          switch kind {
            case "enum" :
              spec = try EnumerationSpec(name: name, json: info, in: environment)
            case "object" :
              spec = try EntitySpec(name: name, json: info, in: environment)
            default :
              throw Exception("unsupported type kind '\(kind)'")
          }
          environment[name] = spec
        }

        // Create a list of the implied inverse relationships.
        var impliedEntityRelationships : [(entity: EntitySpec, relationship: RelationshipSpec)] = []
        for entity in environment.values.compactMap({$0 as? EntitySpec}) {
          for relationship in entity.properties.values.compactMap({$0 as? RelationshipSpec}) {
            guard let relatedEntity = environment[relationship.relatedEntityName] as? EntitySpec else { throw Exception("unknown entity name '\(relationship.relatedEntityName)") }
            let inverseRelationship = RelationshipSpec(inverseOf: relationship, on: entity)
            impliedEntityRelationships += [(relatedEntity, inverseRelationship)]
          }
        }

        // Add those implied relationships to the target entity.
        for (entity, relationship) in impliedEntityRelationships {
          try entity.addPropertySpec(relationship)
        }
      }


    public func generateSwiftSource() -> String
      {
        // Note: type specifications are sorted by name to avoid spurious changes in generated code.

        return { enumerationSpecs, entitySpecs in
          """
          // Generated code, do not modify...

          import Foundation
          import Compendium


          struct \(modelName) : GameModel
            {
              // MARK: - Enums -

              \(enumerationSpecs.map({$0.codegenTypeDefinition(for: modelName)}).joined(separator: .newline(2)).indented(4))

              // MARK: - Classes -

              \(entitySpecs.map({$0.codegenTypeDefinition(for: modelName)}).joined(separator: .newline(2)).indented(4))

              // MARK: - Schema -

              public static let schema = Schema(name: "\(modelName)", entities: [
                \(entitySpecs.map({$0.codegenEntityValue()}).joined(separator: "," + .newline()).indented(6))
              ])
            }
          """
        }(
          environment.values.compactMap({$0 as? EnumerationSpec}).sorted(by: {$0.name < $1.name}),
          environment.values.compactMap({$0 as? EntitySpec}).sorted(by: {$0.name < $1.name})
        )
      }
  }
