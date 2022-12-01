/*

*/

import CoreData


class SearchContext<Model: NSManagedObject>
  {
    let managedObjectContext : NSManagedObjectContext
    let searchKey : String
    let ascending : Bool
    let additionalPredicates : [NSPredicate]
    let additionalSortDescriptors : [NSSortDescriptor]

    private(set) var matches : [Model] = []
    private(set) var matchesByName : [String: Model] = [:]


    init(_ managedObjectContext: NSManagedObjectContext, searchKey: String, searchText: String = "", ascending: Bool = true, additionalPredicates: [NSPredicate] = [], additionalSortDescriptors: [NSSortDescriptor] = [])
      {
        self.managedObjectContext = managedObjectContext
        self.searchKey = searchKey
        self.ascending = ascending
        self.additionalPredicates = additionalPredicates
        self.additionalSortDescriptors = additionalSortDescriptors

        search(for: searchText)
      }


    func search(for searchText: String = "")
      {
        let fetchRequest = NSFetchRequest<Model>(entityName: "\(Model.self)")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [searchText != "" ? NSPredicate(format: "%K CONTAINS[cd] \"\(searchText)\"", searchKey) : nil].compactMap({$0}) + additionalPredicates)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: searchKey, ascending: ascending)] + additionalSortDescriptors

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)

        do { try fetchedResultsController.performFetch() }
        catch let error {
          log("failed to fetch: \(error.localizedDescription)")
        }

        matches = fetchedResultsController.fetchedObjects ?? []
        matchesByName = Dictionary(uniqueKeysWithValues: matches.map { ($0.value(forKey: searchKey) as! String, $0) })
      }
  }
