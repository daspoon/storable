/*

*/

import CoreData


@objc(Quiz)
class Quiz : NSManagedObject
  {
    /// Note that school runs April through January, skipping August...
    private static let validMonthIndexes = [3, 4, 5, 6, 8, 9, 10, 11, 0]
    static let shortMonthNames = validMonthIndexes.map { Calendar.current.shortMonthSymbols[$0] }
    static let longMonthNames  = validMonthIndexes.map { Calendar.current.monthSymbols[$0] }


    struct Item : Codable { let question, answer : String }

    @NSManaged var month : Int
    @NSManaged var day : Int
    @NSManaged var itemsData : Data

    var items : [Item] = []


    static func parseDateKey(_ key: String) throws -> (month: Int, day: Int)
      {
        let substrings = key.split(separator: "-")
        guard substrings.count == 2 else { throw ConfigurationError.dataIntegrityError("") }
        guard let month = Self.shortMonthNames.firstIndex(of: String(substrings[0])) else { throw ConfigurationError.dataIntegrityError("") }
        guard let day = Int(substrings[1]) else { throw ConfigurationError.dataIntegrityError("") }
        return (month, day)
      }


    convenience init(dateKey key: String, info: [[String: Any]], context: ConfigurationContext) throws
      {
        self.init(entity: try context.entity(for: Self.self), insertInto: context.managedObjectContext)

        let (mm, dd) = try Self.parseDateKey(key)
        month = mm
        day = dd

        items = try info.map { .init(question: try $0.requiredValue(for: "Q"), answer: try $0.requiredValue(for: "A")) }
        itemsData = try JSONEncoder().encode(items)
      }


    override func awakeFromFetch()
      {
        super.awakeFromFetch()

        do {
          items = try JSONDecoder().decode([Item].self, from: itemsData)
        }
        catch let error {
          log("failed to decode JSON: \(error)")
        }
      }
  }
