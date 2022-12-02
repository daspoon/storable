/*

*/

import CoreData
import UIKit


public class ObjectListViewController<Object: NSManagedObject> : UITableViewController
  {
    let managedObjectContext : NSManagedObjectContext

    var fetchedResultsController : NSFetchedResultsController<Object>!


    public init(managedObjectContext c: NSManagedObjectContext)
      {
        managedObjectContext = c

        super.init(style: .plain)
      }


    func object(at path: IndexPath) -> Object
      { fetchedResultsController.object(at: path) }


    // TODO: provide a method to update the table view by re-executing the fetch request
    // conditionally manage the search field, mode and filter selection...


    // UIViewController

    public override func viewDidLoad()
      {
        super.viewDidLoad()
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
