/*

*/

import UIKit
import CoreData


public class PersonaListViewController : UITableViewController, UISearchResultsUpdating, TabBarCompatible
  {
    enum SortMode : Int, CaseIterable
      {
        case byLevel, byRace

        var image : UIImage
          {
            switch self {
              case .byLevel : return UIImage(systemName: "ruler")!
              case .byRace : return UIImage(systemName: "flag")!
            }
          }
      }


    var fetchedResultsController : NSFetchedResultsController<Persona>!

    var sortMode : SortMode = .byLevel


    func demon(at path: IndexPath) -> Persona
      { fetchedResultsController.object(at: path) }


    func updateTable(searchText: String = "", ascending: Bool = true)
      {
        let config : (searchKey: String, sectionKey: String?, sortKeys: [String])
        switch sortMode {
          case .byLevel :
            config = ("name", nil, ["level", "name"])
          case .byRace :
            config = ("arcana.name", "arcana.name", ["arcana.name", "level"])
        }

        let fetchRequest = DataModel.fetchRequest(for: Persona.self)
        fetchRequest.sortDescriptors = config.sortKeys.map { NSSortDescriptor(key: $0, ascending: true) }
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
          NSPredicate(format: "not arcana.name ENDSWITH[cd] \" P\""),
          NSPredicate(format: "accessible = true"),
          searchText != "" ? NSPredicate(format: "%K CONTAINS[cd] \"" + (searchText) + "\"", config.searchKey) : nil,
        ].compactMap {$0})

        fetchedResultsController = NSFetchedResultsController<Persona>(fetchRequest: fetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: config.sectionKey, cacheName: nil);

        do {
          try fetchedResultsController.performFetch()
        }
        catch let error {
          log("failed to fetch: \(error.localizedDescription)")
        }

        tableView.reloadData()
      }


    @objc func chooseMode(_ sender: UISegmentedControl)
      {
        guard let newMode = SortMode(rawValue: sender.selectedSegmentIndex) else { preconditionFailure("invalid state") }
        guard sortMode != newMode else { return }

        sortMode = newMode

        updateTable()
      }


    // UIViewController

    public override func viewDidLoad()
      {
        super.viewDidLoad()

        title = tabBarTitle

        tableView.register(PersonaListCell.self, forCellReuseIdentifier: "cell")

        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchTextField.placeholder = "Search by name..."
        searchController.searchBar.returnKeyType = .done
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        let segmentedControl = UISegmentedControl(items: SortMode.allCases.map {$0.image})
        segmentedControl.addTarget(self, action: #selector(chooseMode(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = sortMode.rawValue
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)

        updateTable()
      }


    // UITableViewDataSource

    public override func numberOfSections(in sender: UITableView) -> Int
      { fetchedResultsController.sections?.count ?? 0 }


    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections![i].numberOfObjects }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: PersonaListCell.self, withIdentifier: "cell")
        cell.content = (persona: demon(at: path), options: sortMode == .byLevel ? [.showDisclosure, .showArcana] : [.showDisclosure])
        return cell
      }


    // UITableViewDelegate

    public override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      { fetchedResultsController.sections![i].name }


    public override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        let detailViewController = PersonaViewController(persona: fetchedResultsController.object(at: path))

        navigationController?.pushViewController(detailViewController, animated: true)
      }


    public override func tableView(_ sender: UITableView, trailingSwipeActionsConfigurationForRowAt path: IndexPath) -> UISwipeActionsConfiguration?
      {
        let demon = demon(at: path)
        guard demon.captured else { return nil }

        return .init(actions: [.init(style: .destructive, title: "Reset") { (action, view, completion) in
          demon.captured = false
          sender.reloadRows(at: [path], with: .automatic)
          completion(true)
          NotificationCenter.default.post(name: .dataStoreNeedsSave, object: nil)
        }])
      }


    // UISearchResultsUpdating

    public func updateSearchResults(for searchController: UISearchController)
      { updateTable(searchText: searchController.searchBar.text ?? "") }


    // TabBarCompatible

    public var tabBarTitle : String
      { "Personas" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "eyeglasses") }
  }
