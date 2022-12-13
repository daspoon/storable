// Generated code, do not modify...

import Foundation
import Compendium


struct SMT5 : GameModel
  {
    // MARK: - Enums -

    public enum Affinity : Int, Enumeration
      {
        case physical
        case fire
        case ice
        case electric
        case force
        case light
        case dark
        case almighty
        case ailment
        case recovery
        case support

        public init(json: String) throws {
          switch json {
            case "phy" : self = .physical
            case "fir" : self = .fire
            case "ice" : self = .ice
            case "ele" : self = .electric
            case "for" : self = .force
            case "lig" : self = .light
            case "dar" : self = .dark
            case "alm" : self = .almighty
            case "ail" : self = .ailment
            case "rec" : self = .recovery
            case "sup" : self = .support
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .physical : return "physical"
            case .fire : return "fire"
            case .ice : return "ice"
            case .electric : return "electric"
            case .force : return "force"
            case .light : return "light"
            case .dark : return "dark"
            case .almighty : return "almighty"
            case .ailment : return "ailment"
            case .recovery : return "recovery"
            case .support : return "support"
          }
        }

        var element : Element? { .init(rawValue: rawValue) }
    }

    public enum Ailment : Int, Enumeration
      {
        case charm
        case seal
        case confuse
        case poison
        case sleep
        case mirage

        public init(json: String) throws {
          switch json {
            case "charm" : self = .charm
            case "seal" : self = .seal
            case "confuse" : self = .confuse
            case "poison" : self = .poison
            case "sleep" : self = .sleep
            case "mirage" : self = .mirage
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .charm : return "charm"
            case .seal : return "seal"
            case .confuse : return "confuse"
            case .poison : return "poison"
            case .sleep : return "sleep"
            case .mirage : return "mirage"
          }
        }
    }

    public enum Element : Int, Enumeration
      {
        case physical
        case fire
        case ice
        case electric
        case force
        case light
        case dark

        public init(json: String) throws {
          switch json {
            case "phy" : self = .physical
            case "fir" : self = .fire
            case "ice" : self = .ice
            case "ele" : self = .electric
            case "for" : self = .force
            case "lig" : self = .light
            case "dar" : self = .dark
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .physical : return "physical"
            case .fire : return "fire"
            case .ice : return "ice"
            case .electric : return "electric"
            case .force : return "force"
            case .light : return "light"
            case .dark : return "dark"
          }
        }
    }

    public enum Resistance : Int, Enumeration
      {
        case weak  = 1125
        case none  = 100
        case strong  = 50
        case null  = 0
        case repel  = -100
        case drain  = -1100

        public init(json: String) throws {
          switch json {
            case "w" : self = .weak
            case "-" : self = .none
            case "s" : self = .strong
            case "n" : self = .null
            case "r" : self = .repel
            case "d" : self = .drain
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .weak : return "weak"
            case .none : return "none"
            case .strong : return "strong"
            case .null : return "null"
            case .repel : return "repel"
            case .drain : return "drain"
          }
        }
    }

    public enum SkillType : Int, Enumeration
      {
        case physical
        case fire
        case ice
        case electric
        case force
        case light
        case dark
        case almighty
        case ailment
        case recovery
        case support
        case other
        case passive

        public init(json: String) throws {
          switch json {
            case "phy" : self = .physical
            case "fir" : self = .fire
            case "ice" : self = .ice
            case "ele" : self = .electric
            case "for" : self = .force
            case "lig" : self = .light
            case "dar" : self = .dark
            case "alm" : self = .almighty
            case "ail" : self = .ailment
            case "rec" : self = .recovery
            case "sup" : self = .support
            case "oth" : self = .other
            case "pas" : self = .passive
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .physical : return "physical"
            case .fire : return "fire"
            case .ice : return "ice"
            case .electric : return "electric"
            case .force : return "force"
            case .light : return "light"
            case .dark : return "dark"
            case .almighty : return "almighty"
            case .ailment : return "ailment"
            case .recovery : return "recovery"
            case .support : return "support"
            case .other : return "other"
            case .passive : return "passive"
          }
        }

        var element : Element? { .init(rawValue: rawValue) }
        var affinity : Affinity? { .init(rawValue: rawValue) }
    }

    public enum Statistic : Int, Enumeration
      {
        case healthPoints
        case manaPoints
        case strength
        case vitality
        case magic
        case agility
        case luck

        public init(json: String) throws {
          switch json {
            case "healthPoints" : self = .healthPoints
            case "manaPoints" : self = .manaPoints
            case "strength" : self = .strength
            case "vitality" : self = .vitality
            case "magic" : self = .magic
            case "agility" : self = .agility
            case "luck" : self = .luck
            default :
              throw Exception("invalid value for \(Self.self)")
          }
        }

        public var name : String {
          switch self {
            case .healthPoints : return "healthPoints"
            case .manaPoints : return "manaPoints"
            case .strength : return "strength"
            case .vitality : return "vitality"
            case .magic : return "magic"
            case .agility : return "agility"
            case .luck : return "luck"
          }
        }
    }

    // MARK: - Classes -

    @objc(Demon)
    public class Demon : Object, DemonModel
      {
        typealias Game = SMT5
        @Persistent var affinities : [Int]
        @Persistent var ailmentResistances : [Resistance]
        @NSManaged var captured : Bool
        @Persistent var elementResistances : [Resistance]
        @NSManaged var level : Int
        @NSManaged var name : String
        @NSManaged var race : Race
        @NSManaged var skillGrants : Set<SkillGrant>
        @Persistent var statistics : [Int]
      }

    @objc(Race)
    public class Race : Object, RaceModel
      {
        typealias Game = SMT5
        @NSManaged var consumingFusions : Set<RaceFusion>
        @NSManaged var demons : Set<Demon>
        @NSManaged var name : String
        @NSManaged var producingFusions : Set<RaceFusion>
      }

    @objc(RaceFusion)
    public class RaceFusion : Object, RaceFusionModel
      {
        typealias Game = SMT5
        @NSManaged var index : Int
        @NSManaged var inputs : Set<Race>
        @NSManaged var output : Race
      }

    @objc(Skill)
    public class Skill : Object, SkillModel
      {
        typealias Game = SMT5
        @NSManaged var cost : Int
        @NSManaged var effect : String
        @NSManaged var grants : Set<SkillGrant>
        @NSManaged var name : String
        @Persistent var type : SkillType
      }

    @objc(SkillGrant)
    public class SkillGrant : Object, SkillGrantModel
      {
        typealias Game = SMT5
        @NSManaged var demon : Demon
        @NSManaged var level : Int
        @NSManaged var skill : Skill
      }

    @objc(State)
    public class State : Object, StateModel
      {
        typealias Game = SMT5
        @NSManaged var playerLevel : Int
      }

    // MARK: - Schema -

    public static let schema = Schema(name: "SMT5", entities: [
      Entity(Demon.self, identity: .name, properties: [
        Attribute("affinities", codableType: [Int].self),
        Attribute("ailmentResistances", codableType: [Resistance].self, ingestKey: .element("ailments"), transform: Unpack(), defaultValue: "------"),
        Attribute("captured", nativeType: Bool.self, ingestKey: .ignore, defaultValue: false),
        Attribute("elementResistances", codableType: [Resistance].self, ingestKey: .element("resists"), transform: Unpack(), defaultValue: "------"),
        Attribute("level", nativeType: Int.self, ingestKey: .element("lvl")),
        Attribute("name", nativeType: String.self, ingestKey: .key),
        Relationship("race", arity: .toOne, relatedEntityName: "Race", inverseName: "demons", deleteRule: .nullify, inverseArity: .toMany, inverseDeleteRule: .cascade, ingestKey: .element("race"), ingestMode: .reference),
        Relationship("skillGrants", arity: .toMany, relatedEntityName: "SkillGrant", inverseName: "demon", deleteRule: .cascade, inverseArity: .toOne, inverseDeleteRule: .nullify, ingestKey: .element("skills"), ingestMode: .create),
        Attribute("statistics", codableType: [Int].self, ingestKey: .element("stats"))
      ]),
      Entity(Race.self, identity: .name, properties: [
        Attribute("name", nativeType: String.self, ingestKey: .key)
      ]),
      Entity(RaceFusion.self, identity: .anonymous, properties: [
        Attribute("index", nativeType: Int.self),
        Relationship("inputs", arity: .toMany, relatedEntityName: "Race", inverseName: "consumingFusions", deleteRule: .cascade, inverseArity: .toMany, inverseDeleteRule: .nullify, ingestKey: .element("inputs"), ingestMode: .create),
        Relationship("output", arity: .toOne, relatedEntityName: "Race", inverseName: "producingFusions", deleteRule: .nullify, inverseArity: .toMany, inverseDeleteRule: .cascade, ingestKey: .element("output"), ingestMode: .reference)
      ]),
      Entity(Skill.self, identity: .name, properties: [
        Attribute("cost", nativeType: Int.self, defaultValue: 0),
        Attribute("effect", nativeType: String.self),
        Attribute("name", nativeType: String.self, ingestKey: .key),
        Attribute("type", codableType: SkillType.self, ingestKey: .element("element"))
      ]),
      Entity(SkillGrant.self, identity: .anonymous, properties: [
        Attribute("level", nativeType: Int.self, ingestKey: .value),
        Relationship("skill", arity: .toOne, relatedEntityName: "Skill", inverseName: "grants", deleteRule: .nullify, inverseArity: .toMany, inverseDeleteRule: .cascade, ingestKey: .key, ingestMode: .reference)
      ]),
      Entity(State.self, identity: .singleton, properties: [
        Attribute("playerLevel", nativeType: Int.self, ingestKey: .ignore, defaultValue: 1)
      ])
    ])
  }
