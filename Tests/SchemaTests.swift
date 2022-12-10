import XCTest
@testable import Compendium


final class SchemaTests : XCTestCase
  {
    let schema = SMT5.schema


    func testObjectModelCreation() throws
      {
        _ = try schema.createManagedObjectModel()
      }


    func testDataSourceIngestion() throws
      {
        let dataSource = DataSource(bundle: try MockBundle(), definitions: [
          .entitySet(name: "Race",  content: .init(resourceName: "comp-config", keyPath: "races", format: .array)),
          .entitySet(name: "Demon", content: .init(resourceName: "demon-data")),
          .entitySet(name: "Skill", content: .init(resourceName: "skill-data")),
        ])

        _ = try DataStore(schema: schema, dataSource: dataSource, reset: true)
      }
  }
