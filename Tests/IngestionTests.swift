/*

  Created by David Spooner

  Test functionality relating to object ingestion.

*/

import XCTest
import Storable


final class IngestionTests : XCTestCase
  {
    // Define an object model

    enum Resistance : String, Codable, Ingestible, Storable
      { case weak="w", normal="-", strong="s", null="n", repel="r", drain="d" }

    class Demon : Entity {
      @Attribute("name", ingestKey: .key) var name : String
      @Attribute("level", ingestKey: "lvl") var level : Int
      @Attribute("stats") var stats : [Int]
      @Attribute("resists", transform: { (s: String) in s.map {String($0)} }) var resists : [Resistance]
      @Relationship("race", inverseName: "demons", deleteRule: .nullifyDeleteRule) var race : Race
      @Relationship("grants", inverseName: "demon", deleteRule: .nullifyDeleteRule) var grants : Set<Grant>
    }

    class Race : Entity {
      @Attribute("name", ingestKey: .key) var name : String
      @Relationship("demons", inverseName: "race", deleteRule: .cascadeDeleteRule) var demons : Set<Demon>
    }

    class Skill : Entity {
      @Attribute("name") var name : String
      @Attribute("effect") var effect : String
      @Relationship("grants", inverseName: "skill", deleteRule: .cascadeDeleteRule) var grants : Set<Grant>
    }

    class Grant : Entity {
      @Attribute("level", ingestKey: .key) var level : Int
      @Relationship("skill", inverseName: "grants", deleteRule: .nullifyDeleteRule) var skill : Skill
      @Relationship("demon", inverseName: "grants", deleteRule: .nullifyDeleteRule) var demon : Demon
    }


    /// Test ingestion of a data set
    func testIngestion() throws
      {
        let store = try createAndOpenStoreWith(schema: try Schema(objectTypes: [Demon.self, Race.self, Skill.self, Grant.self]))

        let bundle = try TestIngestSource(resources: [
          "race-data": [ "Devil", "Justice", "Magician" ],
          "demon-data": [
            "Pixie": [
              "lvl": 2,
              "race": "Magician",
              "resists": "-w--s--",
              "skills": [ "Dia": 0, "Zio": 3 ],
              "stats": [ 2, 3, 2, 4, 2 ],
            ],
            "Ukobach": [
              "lvl": 3,
              "race": "Devil",
              "resists": "-sw----",
              "skills": [ "Agi": 0, "Resist Fire": 6 ],
              "stats": [ 3, 4, 3, 4, 2 ],
            ],
            "Orobas": [
              "lvl": 8,
              "race": "Magician",
              "resists": "-sw----",
              "skills": [ "Agi": 0, "Dodge Ice": 10 ],
              "stats": [ 4, 10, 6, 10, 6 ]
            ],
            "Lilim": [
              "lvl": 10,
              "race": "Devil",
              "resists": "-----ws",
              "skills": [ "Zio": 0, "Mudo": 0 ],
              "stats": [ 4, 11, 5, 9, 8 ],
            ],
          ],
          "skill-data": [
            ["name": "Agi", "effect": "Light HP restore"],
            ["name": "Dia", "effect": "Light HP restore"],
            ["name": "Mudo", "effect": "Low chance of dark insta-kill"],
            ["name": "Resist Fire", "effect": "Reduce damage taken from fire attacks"],
            ["name": "Zio", "effect": "Light elec damage to one foe"],
          ],
        ])

        // ingest data
        try store.ingest(from: bundle, methods: [
          EntityIngestMethod(type: Race.self, keyPath: "race-data", format: .dictionaryAsArrayOfKeys),
          EntityIngestMethod(type: Demon.self, keyPath: "demon-data", format: .dictionary),
          EntityIngestMethod(type: Skill.self, keyPath: "skill-data", format: .array),
        ])

        // TODO: Check for expected objects and relations...

      }
  }
