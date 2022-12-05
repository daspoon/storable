import XCTest
@testable import Compendium


final class SchemaTests : XCTestCase
  {
    let schema = Schema(name: "SMT5", entities: [
          Entity("Configuration", identity: .singleInstance),
          Entity("Race"),
          Entity("Skill", properties: [
            IntegerAttribute("cost"),
            StringAttribute("effect"),
            TransformableAttribute("element", of: Element.self),
          ]),
          Entity("SkillGrant", identity: .anonymous, properties: [
            IntegerAttribute("level", ingestKey: .value),
            Relationship.toOne("skill", ingestKey: .name, relatedEntityName: "Skill", inverseName: "grants", inverseArity: .toMany),
          ]),
          Entity("Demon", properties: [
            Relationship.toOne("race", relatedEntityName: "Race", inverseName: "demons", inverseArity: .toMany),
            IntegerAttribute("lvl"),
            CodableAttribute("stats", of: [Int].self),
            TransformableAttribute("resists", of: Resistances.self),
            Relationship.toMany("skills", relatedEntityName: "SkillGrant", inverseName: "demon", inverseArity: .toOne),
          ]),
        ])


    func testObjectModelCreation() throws
      {
        _ = try schema.createManagedObjectModel()
      }


    func testDataSourceIngestion() throws
      {
        let dataSource = DataSource(bundle: Bundle(for: SchemaTests.self), definitions: [
          .entitySet(name: "Configuration"),
          .entitySet(name: "Race",  content: .init(resourceName: "comp-config", keyPath: "races", format: .array)),
          .entitySet(name: "Demon", content: .init(resourceName: "demon-data")),
          .entitySet(name: "Skill", content: .init(resourceName: "skill-data")),
        ])

        _ = try DataStore(schema: schema, dataSource: dataSource, reset: true)
      }
  }
