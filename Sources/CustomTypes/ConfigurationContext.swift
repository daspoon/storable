/*

*/

import CoreData


class ConfigurationContext
  {
    let dataModel : DataModel

    private(set) var configuration : Configuration!

    private(set) var demonCount : Int = 0

    private var fusions : [Set<Persona>: Persona] = [:]


    init(dataModel dm: DataModel, info: [String: Any]) throws
      {
        dataModel = dm
        configuration = try Configuration(info: info, context: self)
      }


    var managedObjectContext : NSManagedObjectContext
      { dataModel.managedObjectContext }


    func entity<T: NSManagedObject>(for type: T.Type) throws -> NSEntityDescription
      {
        guard let entity = dataModel.entity(for: type) else { throw ConfigurationError.invalidEntity(name: "\(type)") }
        return entity
      }


    func race(named name: String) throws -> Arcana
      { try dataModel.fetchObject(named: name) }

    func demon(named name: String) throws -> Persona
      { try dataModel.fetchObject(named: name) }

    func skill(named name: String) throws -> Skill
      { try dataModel.fetchObject(named: name) }


    func confidantForRace(named name: String) throws -> Confidant?
      { try dataModel.findObject(of: Confidant.self, satisfying: .init(format: "arcanum.name = %@", name)) }


    func allocateDemonIndex() -> Int
      {
        defer { demonCount += 1 }
        return demonCount
      }


    @discardableResult
    func createFusion(kind: Fusion.Kind, output: Persona, inputs: Set<Persona>) throws -> Fusion?
      {
        precondition(inputs.count > 0 && inputs.contains(output) == false)

        if let existing = fusions[inputs] {
          log("refusing to define \(output.name) as \(kind) fusion of \(inputs.map{$0.name}); already defined as \(existing.name)")
          return nil
        }

        defer { fusions[inputs] = output }

        return try Fusion(kind: kind, output: output, inputs: inputs, context: self)
      }

  }
