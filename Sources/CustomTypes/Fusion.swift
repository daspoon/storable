/*

*/

import CoreData


@objc(Fusion)
class Fusion : NSManagedObject
  {
    @objc enum Kind : Int, CaseIterable { case normal, element, race, special }

    @NSManaged var kind : Kind
    @NSManaged var output : Persona
    @NSManaged var inputs : Set<Persona>
    @NSManaged var minInputLevel : Int16
    @NSManaged var maxInputLevel : Int16


    convenience init(kind: Kind, output: Persona, inputs: Set<Persona>, context: ConfigurationContext) throws
      {
        precondition(inputs.count > 0)

        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        let levels = inputs.map {$0.level}
        self.kind = kind
        self.output = output
        self.inputs = inputs
        self.minInputLevel = levels.min()!
        self.maxInputLevel = levels.max()!
      }


    override var description : String
      { "\(output.name) = \(inputs.map({$0.name}).joined(separator: " + "))" }
  }


extension Fusion.Kind : CustomStringConvertible
  {
    var description : String
      {
        switch self {
          case .normal : return "normal"
          case .element : return "element"
          case .race : return "race"
          case .special : return "special"
        }
      }
  }
