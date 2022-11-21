/*

*/

import UIKit
import CoreData


class GiftListViewController : UITableViewController, TabBarCompatible
  {
    var fetchedResultsController : NSFetchedResultsController<Gift>!


    // UIViewController

    override func viewDidLoad()
      {
        navigationItem.title = "Gifts"

        fetchedResultsController = .init(fetchRequest: DataModel.fetchRequest(for: Gift.self, sortDescriptors: [.init(key: "name", ascending: true)]), managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! fetchedResultsController.performFetch()

        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "cell")
      }


    // UITableViewDataSource

    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.fetchedObjects!.count }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "cell")
        let gift = fetchedResultsController.object(at: path)
        cell.keyAndValue = (gift.name, "\(gift.price)")
        return cell
      }


    // UITableViewDelegate

    override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      {
        navigationController?.pushViewController(GiftViewController(gift: fetchedResultsController.object(at: path)), animated: true)
      }


    // TabBarCompatible

    var tabBarTitle : String
      { "Gifts" }

    var tabBarImage : UIImage?
      { UIImage(systemName: "gift") }
  }
