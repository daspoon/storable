/*

*/

import UIKit
import CoreData


public class ObjectViewController<Subject: NSManagedObject> : UITableViewController
  {
    let managedObjectContext : NSManagedObjectContext
    let subject : Subject


    public init(subject s: Subject, managedObjectContext c: NSManagedObjectContext)
      {
        subject = s
        managedObjectContext = c

        super.init(style: .insetGrouped)
      }


    // NSCoding
    required init?(coder: NSCoder)
      { nil }
  }
