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
        class Combatant : Entity {
          override class var abstractClass : Entity.Type { Combatant.self }
          @Attribute("name")
          var name : String
          @Relationship("skills", inverse: "wielders", deleteRule: .nullify)
          var skills : Set<Skill>
        }
        class Companion : Combatant {
          @Attribute("joinDate")
          var joinDate : Date
        }
        class Enemy : Combatant {
          @Attribute("loot")
          var loot : String
        }
        class Skill : Entity {
          @Attribute("name")
          var name : String
          @Relationship("wielders", inverse: "skills", deleteRule: .nullify)
          var wielders : Set<Combatant>
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
        XCTAssertEqual(hack.wielders, [orc, dwarf])
        XCTAssertEqual(slash.wielders, [goblin, elf])
      }


    func testInheritedNameConflict() throws
      {
        // Define entities related by inheritance which have define a same-named attribute
        class Super : Entity {
          @Attribute("id")
          var id : String
        }
        class Sub : Super {
          @Attribute("id")
          var id2 : String
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
