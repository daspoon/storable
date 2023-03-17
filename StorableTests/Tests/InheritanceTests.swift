/*

  Created by David Spooner

  Tests involving entity inheritance.

*/

import XCTest
import Storable


final class InheritanceTests : XCTestCase
  {
    func testAbstractRelationship() throws
      {
        // Define a Skill entity related to an abstract Combatant entity with subclasses Companion and Enemy
        @Entity class Combatant : Entity {
          override class var abstractClass : Entity.Type { Combatant.self }
          @Attribute var name : String
          @Relationship(inverse: "wielders", deleteRule: .nullify) var skills : Set<Skill>
        }
        @Entity class Companion : Combatant {
          @Attribute var joinDate : Date
        }
        @Entity class Enemy : Combatant {
          @Attribute var loot : String
        }
        @Entity class Skill : Entity {
          @Attribute var name : String
          @Relationship(inverse: "skills", deleteRule: .nullify) var wielders : Set<Combatant>
        }

        // Create and open a store
        let store = try createAndOpenStoreWith(schema: Schema(objectTypes: [Skill.self, Companion.self, Enemy.self]))

        // Create some related combatants and skills
        let hack = try store.create(Skill.self) { $0.name = "hack" }
        let slash = try store.create(Skill.self) { $0.name = "slash" }
        let orc = try store.create(Enemy.self) { $0.name = "orc"; $0.loot = "axe"; $0.skills = [hack] }
        let goblin = try store.create(Enemy.self) { $0.name = "goblin"; $0.loot = "sword"; $0.skills = [slash]  }
        let dwarf = try store.create(Companion.self) { $0.name = "dwarf"; $0.joinDate = Date(); $0.skills = [hack] }
        let elf = try store.create(Companion.self) { $0.name = "elf"; $0.joinDate = Date(); $0.skills = [slash]}
        try store.save()

        // Retrieve the combatants of each skill, which include both companions and enemies
        if hack.wielders != [orc, dwarf] { XCTFail("") }
        if slash.wielders != [goblin, elf] { XCTFail("") }
      }

    #if false
    // Swift prevents declaring managed properties with the names already taken by ancestor entities, as desired.
    func testInheritedNameConflict() throws
      {
        @Entity class Super : Entity {
          @Attribute var contested : Int
        }
        @Entity class Sub1 : Super {
          @Attribute var contested : Int
        }
        @Entity class Sub2 : Super {
          @Attribute override var contested : Int
        }
        @Entity class Sub3 : Super {
          @Attribute var contested : String
        }
        @Entity class Sub4 : Super {
          @Relationship(inverse: "", deleteRule: .deny) var contested : Entity
        }
      }
    #endif
  }
