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


    func testInheritedNameConflict() throws
      {
        // Define entities related by inheritance which have define a same-named attribute
        // Note that Swift allows the override attribute because 'id' is a computed property.
        // TODO: disallow use of override in conjunction with managed property macros
        @Entity class Super : Entity {
          @Attribute var id : String
        }
        @Entity class Sub : Super {
          @Attribute override var id : String
        }

        // Attempting to create a schema must fail
        do {
          _ = try Schema(objectTypes: [Sub.self])
          XCTFail("expected error not thrown")
        }
        catch let error {
          print(error)
        }
      }
  }
