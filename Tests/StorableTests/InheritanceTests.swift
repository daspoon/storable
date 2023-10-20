/*

  Created by David Spooner

  Tests involving entity inheritance.

*/

#if swift(>=5.9)

import XCTest
import Storable


final class InheritanceTests : XCTestCase
  {
    func testAbstractRelationship() throws
      {
        // Define a Skill entity related to an abstract Combatant entity with subclasses Companion and Enemy
        @ManagedObject class Combatant : ManagedObject {
          override class var abstractClass : ManagedObject.Type { Combatant.self }
          @Attribute var name : String
          @Relationship(inverse: "wielders", deleteRule: .nullify) var skills : Set<Skill>
        }
        @ManagedObject class Companion : Combatant {
          @Attribute var joinDate : Date
        }
        @ManagedObject class Enemy : Combatant {
          @Attribute var loot : String
        }
        @ManagedObject class Skill : ManagedObject {
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
        @ManagedObject class Super : ManagedObject {
          @Attribute var contested : Int
        }
        @ManagedObject class Sub1 : Super {
          @Attribute var contested : Int
        }
        @ManagedObject class Sub2 : Super {
          @Attribute override var contested : Int
        }
        @ManagedObject class Sub3 : Super {
          @Attribute var contested : String
        }
        @ManagedObject class Sub4 : Super {
          @Relationship(inverse: "", deleteRule: .deny) var contested : ManagedObject
        }
      }
    #endif
  }

#endif
