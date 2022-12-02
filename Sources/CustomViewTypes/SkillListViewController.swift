/*

  Present either the list of skill types (as sections) or the list of skills matching the search term, according to whether or not the search bar is active...

*/

import UIKit
import CoreData


public class SkillListViewController<Model: GameModel> : ObjectListViewController<Model.Skill>, UISearchResultsUpdating, TabBarCompatible
  {
    enum SortMode : Int, CaseIterable
      {
        case name, type

        var image : UIImage
          {
            switch self {
              case .name : return UIImage(systemName: "signature")!
              case .type : return UIImage(systemName: "folder")!
            }
          }
      }


    var sortMode : SortMode = .type

    var searchController : UISearchController!


    func updateTable(searchText: String = "")
      {
        let config : (searchKey: String, sectionKey: String?, sortKeys: [String])
        switch sortMode {
          case .name :
            config = ("name", nil, ["name"])
          case .type :
            config = ("element", "element", ["element", "cost", "name"])
        }

        let fetchRequest = fetchRequest(for: Model.Skill.self)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
          NSPredicate(format: "unique = nil"),
          searchText != "" ? NSPredicate(format: "%K CONTAINS[cd] \"\(searchText)\"", config.searchKey, searchText) : nil,
        ].compactMap {$0})
        fetchRequest.sortDescriptors = config.sortKeys.map { NSSortDescriptor(key: $0, ascending: true) }

        fetchedResultsController = NSFetchedResultsController<Model.Skill>(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: config.sectionKey, cacheName: nil)
        try! fetchedResultsController.performFetch()

        tableView.reloadData()
      }


    @objc func chooseSortMode(_ sender: UISegmentedControl)
      {
        guard let mode = SortMode(rawValue: sender.selectedSegmentIndex) else { preconditionFailure("invalid state") }
        guard mode != sortMode else { return }

        sortMode = mode

        updateTable(searchText: searchController.searchBar.text ?? "")
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

        let segmentedControl = UISegmentedControl(items: SortMode.allCases.map {$0.image})
        segmentedControl.addTarget(self, action: #selector(chooseSortMode(_:)), for: .valueChanged)
        segmentedControl.selectedSegmentIndex = sortMode.rawValue
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)

        tableView.register(SkillCell<Model>.self, forCellReuseIdentifier: "skillCell")

        updateTable()
      }


    // UITableViewDataSource

    public override func numberOfSections(in sender: UITableView) -> Int
      { fetchedResultsController.sections!.count }


    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections![i].numberOfObjects }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: SkillCell<Model>.self, withIdentifier: "skillCell")
        let skill = fetchedResultsController.object(at: path)
        cell.content = (skill, sortMode == .name ? [.type] : [])
        return cell
      }


    // UITableViewDelegate

    public override func tableView(_ tableView: UITableView, titleForHeaderInSection i: Int) -> String?
      { fetchedResultsController.sections![i].name }


    public override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        let skill = fetchedResultsController.object(at: path)
        navigationController?.pushViewController(SkillViewController<Model>(skill: skill, managedObjectContext: managedObjectContext), animated: true)
      }


    // UISearchResultsUpdating

    public func updateSearchResults(for sender: UISearchController)
      { updateTable(searchText: sender.searchBar.text ?? "") }


    // TabBarCompatible

    public var tabBarTitle : String
      { "Skills" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "wrench.fill") }
  }
