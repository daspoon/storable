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
              spec = try EnumTypeSpec(name: name, json: info, in: environment)
            case "object" :
              let entity = try ObjectTypeSpec(name: name, json: info, in: environment)
              spec = entity
            default :
              throw Exception("unsupported type kind '\(kind)'")
          }
          environment[name] = spec
        }

        // Create a list of the implied inverse relationships.
        var inversePairs : [(entity: Entity, relationship: Relationship)] = []
        for entity in environment.values.compactMap({$0 as? Entity}) {
          for relationship in entity.relationships {
            guard let target = environment[relationship.relatedEntityName] as? Entity else { throw Exception("unknown entity name '\(relationship.relatedEntityName)") }
            let inverse = Relationship(
              name: relationship.inverseName,
              arity: relationship.inverseArity,
              deleteRule: relationship.inverseDeleteRule,
              relatedEntityName: entity.name,
              inverseName: relationship.name,
              inverseArity: relationship.arity,
              inverseDeleteRule: relationship.deleteRule,
              ingest: nil
            )
            inversePairs += [(target, inverse)]
          }
        }

        // Add those implied relationships to the target entity.
        for (entity, relationship) in inversePairs {
          try entity.addProperty(relationship)
        }
      }


    public var swiftText : String
      {
        """
        // Generated code, do not modify...

        import Compendium

        struct \(modelName) : GameModel {
          \(environment.values.map({$0.generateSwiftText(for: modelName)}).joined(separator: "\n\n"))
        }
        """
      }


    public var managedObjectModel : NSManagedObjectModel
      {
        abort()
      }
  }
