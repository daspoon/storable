/*

  Created by David Spooner

  Test functionality relating to object ingestion.

*/

#if swift(>=5.9)

import XCTest
import Storable


final class IngestionTests : XCTestCase
  {
    // Define an object model

    enum Resistance : String, Codable, Ingestible, Storable
      { case weak="w", normal="-", strong="s", null="n", repel="r", drain="d" }

    @ManagedObject class Demon : ManagedObject {
      @Attribute(ingestKey: .key) var name : String
      @Attribute(ingestKey: "lvl") var level : Int
      @Attribute var stats : [Int]
      @Attribute(defaultValue: "-------", transform: {(s: String) in s.map {String($0)}}) var resists : [Resistance]
      @Relationship(inverse: "demons", deleteRule: .nullify) var race : Race
      @Relationship(inverse: "demon", deleteRule: .nullify) var grants : Set<Grant>
    }

    @ManagedObject class Race : ManagedObject {
      @Attribute(ingestKey: .key) var name : String
      @Relationship(inverse: "race", deleteRule: .cascade) var demons : Set<Demon>
    }

    @ManagedObject class Skill : ManagedObject {
      @Attribute var name : String
      @Attribute var effect : String
      @Relationship(inverse: "skill", deleteRule: .cascade) var grants : Set<Grant>
    }

    @ManagedObject class Grant : ManagedObject {
      @Attribute(ingestKey: .key) var level : Int
      @Relationship(inverse: "grants", deleteRule: .nullify) var skill : Skill
      @Relationship(inverse: "grants", deleteRule: .nullify) var demon : Demon
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

#endif
