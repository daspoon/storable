/*

*/

import UIKit
import Combine
import CoreData


public class DataModel
  {
    public enum GameType { case p5r, smt5 }

    public private(set) static var shared : DataModel!
    private static let semaphore = DispatchSemaphore(value: 1)

    let gameType : GameType
    let managedObjectModel : NSManagedObjectModel
    let managedObjectContext : NSManagedObjectContext

    var configuration : Configuration!
    var observation : AnyCancellable!


    public init(gameType t: GameType)
      {
        Self.semaphore.wait()
        precondition(Self.shared == nil)

        gameType = t

        do {
          // Get the object model
          guard let modelURL = Bundle.module.url(forResource: "DataModel", withExtension: "momd") else { throw NSError(failureReason: "failed to find DataModel") }
          guard let model = NSManagedObjectModel(contentsOf: modelURL) else { throw NSError(failureReason: "failed to create managed object model") }
          managedObjectModel = model

          // Configure the persistent store coordinator
          let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

          // Determine the location of the data store
          let applicationDocumentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
          let dataStoreURL = URL(string: "dataStore.sqlite", relativeTo: applicationDocumentsURL)!

          // Optionally delete the data store (for debugging)
          if ProcessInfo.processInfo.arguments.contains("--resetStore") && FileManager.default.fileExists(atPath: dataStoreURL.path) {
            try FileManager.default.removeItem(at: dataStoreURL)
          }

          // Open the data store, migrating if necessary
          _ = try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: dataStoreURL, options: [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
          ])

          // Create and configure the managed object context
          managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
          managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator

          // Populate the data store if necessary
          configuration = try managedObjectContext.fetch(Self.fetchRequest(for: Configuration.self)).first
          if configuration == nil {
            configuration = try configure()
          }
        }
        catch let error as NSError {
          log("\(error)")
          for suberror in (error.userInfo[NSDetailedErrorsKey] as? [NSError]) ?? [] {
            log("\(suberror)")
          }
          fatalError("exception on startup")
        }

        observation = NotificationCenter.default.publisher(for: .dataStoreNeedsSave, object: nil).sink { self.save($0) }

        Self.shared = self
        Self.semaphore.signal()
      }


    func entity<T: NSManagedObject>(for type: T.Type) -> NSEntityDescription?
      { managedObjectModel.entitiesByName["\(type)"] }


    class func fetchRequest<T: NSManagedObject>(for type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> NSFetchRequest<T>
      {
        let fetchRequest = NSFetchRequest<T>(entityName: NSStringFromClass(T.self))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        return fetchRequest
      }


    func fetchObjects<T: NSManagedObject>(of type: T.Type, satisfying predicate: NSPredicate? = nil, sortedBy sortDescriptors: [NSSortDescriptor] = []) throws -> [T]
      {
        try managedObjectContext.fetch(Self.fetchRequest(for: T.self, predicate: predicate, sortDescriptors: sortDescriptors))
      }


    func findObject<T: NSManagedObject>(of type: T.Type, satisfying predicate: NSPredicate? = nil, sortedBy sortDescriptors: [NSSortDescriptor] = []) throws -> T?
      {
        let results = try fetchObjects(of: type, satisfying: predicate, sortedBy: sortDescriptors)
        switch results.count {
          case 0 :
            return nil
          case 1 :
            return results[0]
          default :
            throw ConfigurationError.ambigousObject(predicate: predicate, entityName: "\(T.self)")
        }
      }


    func findObject<T: NSManagedObject>(of type: T.Type, named name: String) throws -> T?
      {
        try findObject(of: type, satisfying: .init(format: "name = %@", name), sortedBy: [.init(key: "name", ascending: true)])
      }


    func fetchObject<T: NSManagedObject>(of type: T.Type = T.self, named name: String) throws -> T
      {
        switch try findObject(of: type, named: name) {
          case .some(let object) :
            return object
          case .none :
            throw ConfigurationError.unknownObject(name: name, entityName: "\(T.self)")
        }
      }


    func save(_ notification: Notification)
      {
        do {
          try managedObjectContext.save()
        }
        catch let error as NSError {
          log("\(error)")
          for suberror in (error.userInfo[NSDetailedErrorsKey] as? [NSError]) ?? [] {
            log("\(suberror)")
          }
        }
      }


    func configure(from bundle: Bundle = .main) throws -> Configuration
      {
        // Get the expected entity descriptions
        let comp_config = try bundle.loadJSON("comp-config")
        let element_chart = try bundle.loadJSON("element-chart")
        let special_recipes = try bundle.loadJSON("special-recipes", ofType: [String: [String]].self)

        let context = try ConfigurationContext(dataModel: self, info: comp_config)

        log("defining races...")
        let extendedRaceNames = try comp_config.requiredValue(of: [String].self, for: "races", in: "comp-config")
        let races = Dictionary(uniqueKeysWithValues: try extendedRaceNames.map { name in
          (name, try Arcana(name: name, context: context))
        })

        log("defining skills...")
        let skill_data = try bundle.loadJSON("skill-data", ofType: [String: [String: Any]].self)
        _ = Dictionary(uniqueKeysWithValues: try skill_data.map { name, info in
          (name, try Skill(name: name, attributes: info, context: context))
        })

        log("defining demons...")
        // First create a map to distinguish the names of element, DLC, special and party-member demons.
        let elementDemonNames = try element_chart.requiredValue(of: [String].self, for: "elems", in: "element-chart")
        // let specialDemonNames = special_recipes.filter({$1 != []}).keys
        let dlcDemonNames = try comp_config.requiredValue(of: [String].self, for: "dlcDemons", in: "comp-config").flatMap {$0.components(separatedBy: ",")}
        let partyDemonNames = try comp_config.optionalValue(of: [String].self, for: "partyDemons", in: "comp-config") ?? []
        let categoriesByName
          = Dictionary<String, Persona.Category>(uniqueKeysWithValues:
              elementDemonNames.map({($0, .rare)}) +
              // specialDemonNames.map({($0, .special)}) +
              dlcDemonNames.map({($0, .dlc)}) +
              partyDemonNames.map({($0, .party)})
            )
        // Then load the demon data
        for (name, info) in try bundle.loadJSON("demon-data", ofType: [String: [String: Any]].self) {
          _ = try Persona(name: name, attributes: info, category: categoriesByName[name] ?? .normal, context: context)
        }

        // Define fusions: do special fusions first so they take precedence
        log("defining special fusions...")
        for (outputName, inputNames) in special_recipes {
          guard inputNames.isEmpty == false else { continue }
          let output = try context.demon(named: outputName)
          let inputs = try inputNames.map { try context.demon(named: $0) }
          _ = try context.createFusion(kind: .special, output: output, inputs: Set(inputs))
        }

        log("defining normal fusions...")
        let fusion_chart = try bundle.loadJSON("fusion-chart")
        let raceNames = try fusion_chart.requiredValue(of: [String].self, for: "races", in: "fusion-chart")
        let fusionTable = try fusion_chart.requiredValue(of: [[String]].self, for: "table", in: "fusion-chart")
        for i in 0 ..< raceNames.count {
          for j in 0 ..< i {
            let outputRaceName = fusionTable[i][j]
            guard outputRaceName != "None" && outputRaceName != "-" else { continue }
            let outputRace = try context.race(named: outputRaceName)
            let (inputRace1, inputRace2) = (try context.race(named: raceNames[i]), try context.race(named: raceNames[j]))
            _ = try RaceFusion(index: i * raceNames.count + j, output: outputRace, inputs: [inputRace1, inputRace2], context: context)
            for (input1, input2) in inputRace1.members.crossProduct(inputRace2.members) {
              guard input1.rare == input2.rare else { continue }
              let minimumLevel = (input1.level + input2.level) / 2 + 1
              let candidates = Array(outputRace.members.filter({$0.category == .normal})).sorted {$0.level < $1.level}
              guard let output = candidates.first(where: {$0.level >= minimumLevel}) /* ?? candidates.last */ else { continue }
              _ = try context.createFusion(kind: .normal, output: output, inputs: [input1, input2])
            }
          }
        }

        log("defining same-race fusions...")
        for race in races.values {
          let membersByLevel = race.members.filter({!$0.rare}).sorted(by: {$0.level < $1.level})
          for i in 0 ..< membersByLevel.count {
            let p = membersByLevel[i]
            for j in 0 ..< i {
              let q = membersByLevel[j]
              let averageLevel = (p.level + q.level) / 2 + 1
              guard let output = membersByLevel.last(where: {r in r.level <= averageLevel && r.category == .normal && r !== p && r !== q}) else { continue }
              _ = try context.createFusion(kind: .race, output: output, inputs: [p, q])
            }
          }
        }

        log("defining element fusions...")
        // Note: modifierTable is a matrix indexed by race (row) and element demon (column); it provides a level offset when fusing a demon of that race with an element demon
        // Note: the races applicable to element fusion are a subset of those defined in comp-config
        let someRaceNames = try element_chart.requiredValue(of: [String].self, for: "races", in: "element-chart")
        let modifierTable = try element_chart.requiredValue(of: [[Int]].self, for: "table", in: "element-chart")
        guard someRaceNames.count == modifierTable.count else { throw ConfigurationError.dataIntegrityError("The 'races' and 'table' entries of 'element-chart' have mismatched lengths: \(someRaceNames.count) != \(modifierTable.count)") }
        for i in 0 ..< someRaceNames.count {
          guard elementDemonNames.count == modifierTable[i].count else { throw ConfigurationError.dataIntegrityError("The 'table' entry for row '\(i) has the wrong length: \(modifierTable[i].count) != \(elementDemonNames.count)") }
          let race = try context.race(named: someRaceNames[i])
          let siblings = race.members.filter({!$0.rare}).sorted(by: {$0.level < $1.level})
          for j in 0 ..< elementDemonNames.count {
            let element = try context.demon(named: elementDemonNames[j])
            for (k, demon) in siblings.enumerated() {
              var modifier = modifierTable[i][j]
              while (0 ..< siblings.count).contains(k + modifier) {
                let candidate = siblings[k + modifier]
                guard candidate.category == .normal else { modifier += sign(modifier); continue }
                _ = try context.createFusion(kind: .element, output: candidate, inputs: [element, demon])
                break
              }
            }
          }
        }

        if case .p5r = gameType {
          log("defining enemies...")
          let enemy_data = try bundle.loadJSON("enemy-data", ofType: [String: [String: Any]].self)
          for (name, info) in enemy_data {
            _ = try Enemy(name: name, attributes: info, context: context)
          }

          log("defining confidants...")
          let confidant_data = try bundle.loadJSON("confidant-info", ofType: [String: [String: Any]].self)
          for (name, info) in confidant_data {
            _ = try Confidant(for: name, info: info, context: context)
          }

          log("defining gifts...")
          let entityForGiftEffect = try context.entity(for: GiftEffect.self)
          let gift_data = try bundle.loadJSON("gift-info", ofType: [String: Any].self)
          let recipientRaceNames = try gift_data.requiredValue(of: [String].self, for: "recipients")
          for (name, info) in try gift_data.requiredValue(of: [String: [String: Any]].self, for: "gifts") {
            guard name != "" else { continue }
            let gift = try Gift(name: name, info: info, context: context)
            for (i, bonus) in (try info.requiredValue(of: [Int].self, for: "bonuses")).enumerated() {
              guard bonus > 0, let confidant = try context.confidantForRace(named: recipientRaceNames[i]) else { continue }
              let giftEffect = GiftEffect(entity: entityForGiftEffect, insertInto: managedObjectContext)
              giftEffect.gift = gift
              giftEffect.confidant = confidant
              giftEffect.bonus = bonus
            }
          }

          log("defining test questions...")
          for (key, info) in try bundle.loadJSON("classroom-info", ofType: [String: [[String: Any]]].self) {
            _ = try Quiz(dateKey: key, info: info, context: context)
          }

          log("defining crossword puzzles...")
          for info in try bundle.loadJSON("crossword-info", ofType: [[String: Any]].self) {
            _ = try Crossword(info: info, context: context)
          }
        }

        log("saving data store")
        try managedObjectContext.save()

        return context.configuration
      }
  }
