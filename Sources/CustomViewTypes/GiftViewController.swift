/*

*/

import UIKit
import CoreData


class GiftViewController : UITableViewController
  {
    enum Section : Int, CaseIterable
      { case store, price, recipients }


    let gift : Gift

    var effectsController : NSFetchedResultsController<GiftEffect>!


    init(gift g: Gift)
      {
        gift = g

        super.init(style: .insetGrouped)
      }


    // UIViewController

    override func viewDidLoad()
      {
        title = gift.name

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "cell")

        effectsController = NSFetchedResultsController<GiftEffect>(fetchRequest: DataModel.fetchRequest(for: GiftEffect.self, predicate: .init(format: "gift = %@", gift), sortDescriptors: [.init(key: "bonus", ascending: false)]), managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! effectsController.performFetch()
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        switch Section(rawValue: i)! {
          case .store :
            return 1
          case .price :
            return 1
          case .recipients :
            return effectsController.fetchedObjects!.count
        }
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "cell")
        switch Section(rawValue: path.section)! {
          case .store :
            cell.keyAndSubtitle = (gift.store, gift.area)
          case .price :
            cell.key = "\(gift.price)"
          case .recipients :
            let effect = effectsController.fetchedObjects![path.row]
            cell.keyAndValue = (effect.confidant.name, "\(effect.bonus)")
        }
        return cell
      }


    // UITableViewDelegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection i: Int) -> String?
      { "\(Section(rawValue: i)!)" }


    override func tableView(_ sender: UITableView, trailingSwipeActionsConfigurationForRowAt path: IndexPath) -> UISwipeActionsConfiguration?
      {
        guard case .recipients = Section(rawValue: path.section) else { return nil }

        let confidant = effectsController.fetchedObjects![path.row].confidant
        switch gift.recipient {
          case .none :
            return .init(actions: [.init(style: .normal, title: "Give") { (_, _, completion) in
              self.gift.recipient = confidant
              sender.reloadRows(at: [path], with: .automatic)
              completion(true)
              NotificationCenter.default.post(name: .dataStoreNeedsSave, object: nil)
            }])
          case .some(confidant) :
            return .init(actions: [.init(style: .destructive, title: "Take") { (_, _, completion) in
              self.gift.recipient = nil
              sender.reloadRows(at: [path], with: .automatic)
              completion(true)
              NotificationCenter.default.post(name: .dataStoreNeedsSave, object: nil)
            }])
          case .some :
            return nil
        }
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
