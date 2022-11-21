/*

  todo: Style cell to indicate whether or not confidant has been obtained

*/

import UIKit
import CoreData


public class ConfidantListViewController : UITableViewController, UISearchResultsUpdating, TabBarCompatible
  {
    enum Highlight { case confidant, arcanum }

    enum SortMode : Int, CaseIterable
      {
        case confidant, arcanum, availability

        var image : UIImage
          {
            switch self {
              case .confidant : return UIImage(systemName: "signature")!
              case .arcanum : return UIImage(systemName: "flag")!
              case .availability : return UIImage(systemName: "lock.open")!
            }
          }
      }


    struct ConfidantCellConfiguration : GenericTableCellConfiguration
      {
        let primaryLabel = createLabel()
        let secondaryLabel = createSecondaryLabel()
        let unlockLabel = createSecondaryLabel()

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, alignment: .firstBaseline, arrangedSubviews: [primaryLabel, UIView(), unlockLabel]),
              secondaryLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for state: (confidant: Confidant, highlight: Highlight))
          {
            primaryLabel.text = state.highlight == .confidant ? state.confidant.name : state.confidant.arcanum.name
            secondaryLabel.text = state.highlight == .confidant ? state.confidant.arcanum.name : state.confidant.name
            unlockLabel.text = printGameDate(state.confidant.unlock)
          }

        static var accessoryType : UITableViewCell.AccessoryType
          { .disclosureIndicator }
      }

    typealias ConfidantCell = GenericTableCell<ConfidantCellConfiguration>


    var fetchedResultsController : NSFetchedResultsController<Confidant>!
    var highlight : Highlight = .confidant
    var sortMode : SortMode = .availability


    var fetchedConfidants : Array<Confidant>
      { fetchedResultsController.fetchedObjects! }


    @objc func chooseSortMode(_ sender: UISegmentedControl)
      {
        guard let mode = SortMode(rawValue: sender.selectedSegmentIndex) else { preconditionFailure("invalid state") }
        guard mode != sortMode else { return }

        sortMode = mode

        // Change the highlight if appropriate
        switch (sortMode, highlight) {
          case (.confidant, _) : highlight = .confidant
          case (.arcanum, _) : highlight = .arcanum
          default :
            break
        }

        updateTable()
      }


    var sortKeyPaths : [String]
      {
        switch sortMode {
          case .confidant : return ["name"]
          case .arcanum : return ["arcanum.name"]
          case .availability : return ["unlock", highlight == .confidant ? "name" : "arcanum.name"]
        }
      }


    func updateTable(searchText: String = "")
      {
        let fetchRequest = DataModel.fetchRequest(for: Confidant.self)
        fetchRequest.sortDescriptors = sortKeyPaths.map {NSSortDescriptor(key: $0, ascending: true)}
        fetchRequest.predicate = searchText != "" ? NSPredicate(format: "name CONTAINS[cd] \"" + (searchText) + "\" OR arcanum.name CONTAINS[cd] \"" + (searchText) + "\"") : nil

        fetchedResultsController = NSFetchedResultsController<Confidant>(fetchRequest: fetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! fetchedResultsController.performFetch()

        tableView.reloadData()
      }


    // MARK: UIViewController

    public override func viewDidLoad()
      {
        super.viewDidLoad()

        title = tabBarTitle

        tableView.register(ConfidantCell.self, forCellReuseIdentifier: "cell")

        let searchController = UISearchController(searchResultsController: nil)
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

        updateTable()
      }


    // MARK: UITableViewDataSource

    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections?[i].numberOfObjects ?? 0 }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: ConfidantCell.self, withIdentifier: "cell")
        cell.content = (fetchedResultsController.object(at: path), highlight)
        return cell
      }


    // MARK: UITableViewDelegate

    public override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        navigationController?.pushViewController(ConfidantViewController(confidant: fetchedConfidants[path.row]), animated: true)
      }


    // MARK: UISearchResultsUpdating

    public func updateSearchResults(for searchController: UISearchController)
      { updateTable(searchText: searchController.searchBar.text ?? "") }


    // MARK: TabBarCompatible

    public var tabBarTitle : String
      { "Confidants" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "person.3") }
  }
