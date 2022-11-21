/*

*/

import UIKit
import CoreData


class CrosswordListViewController : UITableViewController, TabBarCompatible
  {
    struct CellConfiguration : GenericTableCellConfiguration
      {
        let numberLabel = createLabel(font: secondaryLabelFont, color: .secondaryLabel)
        let questionLabel = createLabel(color: .secondaryLabel)
        let answerLabel = createMultilineLabel(font: secondaryLabelFont, color: .label)

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, alignment: .firstBaseline, spacing: 0, arrangedSubviews: [numberLabel, questionLabel, UIView()]),
              answerLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for crossword: Crossword)
          {
            numberLabel.text = "\(crossword.index): "
            questionLabel.text = crossword.question
            answerLabel.text = "A: " + crossword.answer
          }

        var expandableDetailView : UIView?
          { answerLabel }
      }

    typealias CrosswordCell = GenericTableCell<CellConfiguration>


    var fetchedResultsController : NSFetchedResultsController<Crossword>!


    func updateTable()
      {
        let fetchRequest = DataModel.fetchRequest(for: Crossword.self)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]

        fetchedResultsController = NSFetchedResultsController<Crossword>(fetchRequest: fetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil);

        do {
          try fetchedResultsController.performFetch()
        }
        catch let error {
          log("failed to fetch: \(error.localizedDescription)")
        }

        tableView.reloadData()
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        title = tabBarTitle

        tableView.register(CrosswordCell.self, forCellReuseIdentifier: "cell")

        tableView.allowsSelection = true
        tableView.allowsMultipleSelection = false

        updateTable()
      }


    // UITableViewDataSource

    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections![i].numberOfObjects }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: CrosswordCell.self, withIdentifier: "cell")
        cell.content = fetchedResultsController.object(at: path)
        cell.expandableSubview?.isVisible = sender.isSelected(path)
        return cell
      }


    // UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt path: IndexPath) -> IndexPath?
      {
        guard let cell = tableView.cellForRow(at: path), cell.isSelected else { return path }
        tableView.deselectRow(at: path, animated: true)
        self.tableView(tableView, didDeselectRowAt: path)
        return nil
      }


    override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      { sender.setExpansionState(true, forCellAt: path) }


    override func tableView(_ sender: UITableView, didDeselectRowAt path: IndexPath)
      { sender.setExpansionState(false, forCellAt: path) }


    // TabBarCompatible

    var tabBarTitle : String
      { "Crosswords" }

    var tabBarImage : UIImage?
      { UIImage(systemName: "newspaper") }
  }
