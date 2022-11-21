/*

*/

import UIKit
import CoreData


public class GiftListViewController : UITableViewController, TabBarCompatible
  {
    var fetchedResultsController : NSFetchedResultsController<Gift>!


    // UIViewController

    public override func viewDidLoad()
      {
        navigationItem.title = "Gifts"

        fetchedResultsController = .init(fetchRequest: DataModel.fetchRequest(for: Gift.self, sortDescriptors: [.init(key: "name", ascending: true)]), managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! fetchedResultsController.performFetch()

        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "cell")
      }


    // UITableViewDataSource

    public override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.fetchedObjects!.count }


    public override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "cell")
        let gift = fetchedResultsController.object(at: path)
        cell.keyAndValue = (gift.name, "\(gift.price)")
        return cell
      }


    // UITableViewDelegate

    public override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        navigationController?.pushViewController(GiftViewController(gift: fetchedResultsController.object(at: path)), animated: true)
      }


    // TabBarCompatible

    public var tabBarTitle : String
      { "Gifts" }

    public var tabBarImage : UIImage?
      { UIImage(systemName: "gift") }
  }
