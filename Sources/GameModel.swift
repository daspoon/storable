/*

*/

import CoreData


public protocol GameModel
  {
    /// The enumeration of demon statistics.
    associatedtype Statistic : Enumeration

    /// The enumeration of skill types
    associatedtype SkillType : Enumeration

    /// A sub-enumeration of skill types for which the effect is dependent on caster proficiency.
    associatedtype Affinity : Enumeration

    /// A sub-enumeration of skill types for which the effect is dependent on target resistances.
    associatedtype Element : Enumeration

    /// The enumeration of ailment types.
    associatedtype Ailment : Enumeration

    /// The enumeration of resistance values.
    associatedtype Resistance : Enumeration


    /// The class representing the game playthrough state.
    associatedtype State : StateModel<Self>

    /// The class representing races.
    associatedtype Race : RaceModel<Self>

    /// The class representing demons.
    associatedtype Demon : DemonModel<Self>

    /// The class respresenting skills.
    associatedtype Skill : SkillModel<Self>

    /// The class representing skill grants. (i.e. demon skill assignments by level).
    associatedtype SkillGrant : SkillGrantModel<Self>

    /// The class respresenting binary race fusions.
    associatedtype RaceFusion : RaceFusionModel<Self>
  }


// MARK: --

public protocol StateModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// 
    var playerLevel : Int { get }
  }


// MARK: --

public protocol RaceModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// The name identifying the race.
    var name : String { get }
  }


// MARK: --

public protocol DemonModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// The name identifying the demon.
    var name : String { get }
    /// The race to which the demon belongs.
    var race : Game.Race { get }
    /// The base level of the demon.
    var level : Int { get }
    /// The base statistic values for the demon, indexed by Statistic rawValue.
    var statistics : [Int] { get }
    /// The  base elemental resistances of the demon, indexed by Element rawValue.
    var elementResistances : [Game.Resistance] { get }
    /// The base ailment resistances of the demon, indexed by Ailment rawValue.
    var ailmentResistances : [Game.Resistance] { get }
    /// The base affinities of the demon, indexed by Afinity rawValue.
    var affinities : [Int] { get }

    // State

    var captured : Bool { get set }
  }


// MARK: --

public protocol SkillModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// The name identifying the skill.
    var name : String { get }
    /// The type of the skill.
    var type : Game.SkillType { get }
    /// The cost required to use the skill.
    var cost : Int { get }
    /// A description of the skill effect.
    var effect : String { get }
  }


// MARK: --

public protocol SkillGrantModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// A reference to the granted skill.
    var skill : Game.Skill { get }
    /// A reference to the demon to which the skill is granted.
    var demon : Game.Demon { get }
    /// The demon level at which the skill is granted.
    var level : Int { get }
  }


// MARK: --

public protocol RaceFusionModel<Game> : NSManagedObject
  {
    associatedtype Game : GameModel

    /// The offset within the fusion table.
    var index : Int { get }
    /// The race resulting from the fusion.
    var output : Game.Race { get }
    /// The set of races input to the fusion.
    var inputs : Set<Game.Race> { get }
  }
