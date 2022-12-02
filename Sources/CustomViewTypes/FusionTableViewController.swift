/*

*/

import UIKit
import CoreData


public class FusionTableViewController<Game: GameModel> : ObjectListViewController<Game.RaceFusion>, UISearchBarDelegate, UISearchResultsUpdating, TabBarCompatible
  {
    struct SearchScope : OptionSet
      {
        let rawValue : Int

        init(rawValue v: Int)
          { rawValue = v }

        static var output : Self { .init(rawValue: 1) }
        static var input : Self { .init(rawValue: 2) }
        static var any : Self { .init(rawValue: 3) }

        init(index i: Int)
          { precondition((0 ..< 3).contains(i)); rawValue = i + 1 }

        var index : Int
          { rawValue - 1 }
      }


    var searchController : UISearchController!
    var searchScope : SearchScope = .output


    func updateTable(searchText: String = "")
      {
        let fetchRequest = fetchRequest(for: Game.RaceFusion.self)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "output.name", ascending: true), NSSortDescriptor(key: "index", ascending: true)]
        fetchRequest.predicate = searchText == "" ? nil : NSCompoundPredicate(orPredicateWithSubpredicates: [
          searchScope.contains(.output) ? NSPredicate(format: "output.name CONTAINS[cd] \"" + (searchText) + "\"") : nil,
          searchScope.contains(.input) ? NSPredicate(format: "ANY inputs.name CONTAINS[cd] \"" + (searchText) + "\"") : nil,
        ].compactMap({$0}))

        fetchedResultsController = NSFetchedResultsController<Game.RaceFusion>(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "output.name", cacheName: nil)

        do {
          try fetchedResultsController.performFetch()
        }
        catch let error {
          log("failed to fetch: \(error.localizedDescription)")
        }

        tableView.reloadData()
      }


    // UIViewController

    public override func viewDidLoad()
      {
        super.viewDidLoad()

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "raceCell")

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = "Search by name..."
        searchController.searchBar.returnKeyType = .done
        searchController.searchBar.scopeButtonTitles = ["output", "input", "any"]
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        searchController.searchBar.selectedScopeButtonIndex = searchScope.index

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        updateTable()
      }


    // UITableViewDataSource

    public override func numberOfSections(in tableView: UITableView) -> Int
      { fetchedResultsController.sections?.count ?? 0 }


    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections![i].numberOfObjects }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "raceCell")
        let fusion = fetchedResultsController.object(at: path)
        cell.key = fusion.inputs.map({$0.name}).joined(separator: " + ")
        return cell
      }


    // UITableViewDelegate

    public override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      { fetchedResultsController.sections![i].name }


    // UISearchBarDelegate

    public func searchBar(_ sender: UISearchBar, selectedScopeButtonIndexDidChange i: Int)
      {
        searchScope = SearchScope(index: i)
        updateTable(searchText: sender.text ?? "")
      }


    // UISearchResultsUpdating

    public func updateSearchResults(for searchController: UISearchController)
      { updateTable(searchText: searchController.searchBar.text ?? "") }


    // TabBarCompatible

    public var tabBarTitle : String
      { "Fusion Table" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "tablecells") }
  }
