/*

*/

import UIKit
import CoreData


public class EnemyListViewController : UITableViewController, NSFetchedResultsControllerDelegate, UISearchResultsUpdating
  {
    var fetchedResultsController : NSFetchedResultsController<Enemy>!

    var searchController : UISearchController!


    func updateTable(searchText: String = "", ascending: Bool = true)
      {
        let fetchRequest = DataModel.fetchRequest(for: Enemy.self)
        fetchRequest.propertiesToFetch = ["level", "name"]
        fetchRequest.sortDescriptors = NSSortDescriptor.with(keyPaths: ["level", "name"], ascending: ascending)
        fetchRequest.predicate = searchText != "" ? NSPredicate(format: "name CONTAINS[cd] \"" + (searchText) + "\"") : nil

        fetchedResultsController = NSFetchedResultsController<Enemy>(fetchRequest: fetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! fetchedResultsController.performFetch()

        tableView.reloadData()
      }


    // UIViewController

    public override func viewDidLoad()
      {
        super.viewDidLoad()

        title = tabBarTitle

        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = "Search by name..."
        searchController.searchBar.returnKeyType = .done

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "enemyCell")

        updateTable()
      }


    // UITableViewDataSource

    public override func numberOfSections(in sender: UITableView) -> Int
      { 1 }


    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections![i].numberOfObjects }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "enemyCell")
        let enemy = fetchedResultsController.object(at: path)
        cell.keyAndValue = (enemy.name,"\(enemy.level)")
        return cell
      }


    // UITableViewDelegate

    public override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        navigationController?.pushViewController(EnemyViewController(enemies: fetchedResultsController.fetchedObjects!, selectedIndex: path.row), animated: true)
      }


    // UISearchResultsUpdating

    public func updateSearchResults(for searchController: UISearchController)
      { updateTable(searchText: searchController.searchBar.text ?? "") }
  }


extension EnemyListViewController : TabBarCompatible
  {
    public var tabBarTitle : String
      { "Enemies" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "theatermasks") }
  }
