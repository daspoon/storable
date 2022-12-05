/*

*/

import Foundation
import Compendium


enum Category : String, Codable, Transformable
  { case normal, special, dlc, party }


enum ResistanceElement : String, CaseIterable, Codable
  {
    // NOTE: we need CaseIterable to enable consistent layout
    case physical = "phy"
    case fire = "fir"
    case ice
    case electic = "ele"
    case wind = "for"
    case light = "lig"
    case dark = "dar"

    static var count : Int
      { allCases.count }
  }

enum AffinityElement : String, Codable
  {
    case almighty = "alm"
    case ailment = "ail"
    case healing = "rec"
    case support = "sup"
  }

enum SkillElement : String, Codable
  {
    case passive = "pas"
    case other = "oth"
  }


enum Element : Codable, Transformable, CustomStringConvertible
  {
    case affinity(AffinityElement)
    case resistance(ResistanceElement)
    case skill(SkillElement)

    init(from input: Any) throws
      {
        guard let name = input as? String else { throw Exception("requires string input") }
        switch (AffinityElement(rawValue: name), ResistanceElement(rawValue: name), SkillElement(rawValue: name)) {
          case (.some(let value), .none, .none) :
            self = .affinity(value)
          case (.none, .some(let value), .none) :
            self = .resistance(value)
          case (.none, .none, .some(let value)) :
            self = .skill(value)
          case (.none, .none, .none) :
            throw Exception("invalid element name: \(name)")
          default :
            throw Exception("ambiguous element name: \(name)")
        }
      }

    var description : String
      {
        switch self {
          case .affinity(let v) : return v.rawValue
          case .resistance(let v) : return v.rawValue
          case .skill(let v) : return v.rawValue
        }
      }
  }


enum Resistance : String, Codable, Transformable, CustomStringConvertible
  {
    case weak   = "w"
    case normal = "-"
    case strong = "s"
    case null   = "n"
    case repel  = "r"
    case drain  = "d"

    var value : Int
      {
        switch self {
          case .weak : return 1125
          case .normal : return 100
          case .strong : return 50
          case .null : return 0
          case .repel : return -100
          case .drain : return -1100
        }
      }

    var description : String
      { "\(rawValue)" }
  }


struct Resistances : Codable, Transformable
  {
    var dictionary : [ResistanceElement: Resistance]

    init(from input: Any) throws
      {
        guard let string = input as? String else { throw Exception("requires string input") }
        guard string.count == ResistanceElement.count else { throw Exception("invalid value '\(string)'") }
        dictionary = Dictionary(uniqueKeysWithValues: zip(ResistanceElement.allCases, try string.map {try Resistance(from: String($0))}))
      }

    subscript (_ element: ResistanceElement) -> Resistance
      {
        get { dictionary[element]! }
        set { dictionary[element] = newValue }
      }
  }
