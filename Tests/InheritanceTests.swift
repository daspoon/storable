/*

  Created by David Spooner

*/

import XCTest
@testable import Storable


@objc(Skill)
fileprivate class Skill : Entity
  {
    @Attribute("name")
    var name : String

    @Relationship("wielders", inverseName: "skills", deleteRule: .nullifyDeleteRule)
    var wielders : Set<Combatant>
  }


@objc(Combatant)
fileprivate class Combatant : Entity
  {
    override class var abstractClass : Entity.Type
      { Combatant.self }

    @Attribute("name")
    var name : String

    @Relationship("skills", inverseName: "wielders", deleteRule: .nullifyDeleteRule)
    var skills : Set<Skill>
  }


@objc(Companion)
fileprivate class Companion : Combatant
  {
    @Attribute("joinDate")
    var joinDate : Date
  }


@objc(Enemy)
fileprivate class Enemy : Combatant
  {
    @Attribute("loot")
    var loot : String
  }


final class InheritanceTests : XCTestCase
  {
    func test() throws
      {
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Skill.self, Companion.self, Enemy.self]))

        let hack = try store.create(Skill.self) { $0.name = "hack" }
        let slash = try store.create(Skill.self) { $0.name = "slash" }
        let orc = try store.create(Enemy.self) { $0.name = "orc"; $0.loot = "axe"; $0.skills = [hack] }
        let goblin = try store.create(Enemy.self) { $0.name = "goblin"; $0.loot = "sword"; $0.skills = [slash]  }
        let dwarf = try store.create(Companion.self) { $0.name = "dwarf"; $0.joinDate = Date(); $0.skills = [hack] }
        let elf = try store.create(Companion.self) { $0.name = "elf"; $0.joinDate = Date(); $0.skills = [slash]}

        XCTAssertEqual(hack.wielders, [orc, dwarf])
        XCTAssertEqual(slash.wielders, [goblin, elf])
      }
  }
