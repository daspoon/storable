/*

*/

import UIKit
import CoreData


class QuizViewController : UITableViewController, TabBarCompatible
  {
    struct QuizCellConfiguration : GenericTableCellConfiguration
      {
        let dateLabel = createLabel(color: .secondaryLabel)
        let itemsView = createMultilineLabel()

        var contentSubview : UIView
          { UIStackView(axis: .vertical, arrangedSubviews: [dateLabel, UIView(), itemsView]) }

        func update(_ cell: GenericTableCell<Self>, for quiz: Quiz)
          {
            dateLabel.text = "\(Quiz.shortMonthNames[quiz.month]) \(quiz.day)"
            itemsView.attributedText = quiz.items
              .flatMap({[
                NSAttributedString(string: "Q: " + $0.question, font: Self.secondaryLabelFont, color: .secondaryLabel),
                NSAttributedString(string: "A: " + $0.answer, font: Self.secondaryLabelFont, color: .label),
              ]})
              .joined(separator: .init(string: "\n\n"))
          }

        var expandableDetailView : UIView?
          { return itemsView }

        static var selectionStyle : UITableViewCell.SelectionStyle
          { .none }
      }

    typealias QuizCell = GenericTableCell<QuizCellConfiguration>


    private var fetchedResultsController : NSFetchedResultsController<Quiz>!


    init()
      { super.init(style: .insetGrouped) }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        tableView.register(QuizCell.self, forCellReuseIdentifier: "cell")

        fetchedResultsController = .init(fetchRequest: DataModel.fetchRequest(for: Quiz.self, sortDescriptors: [.init(key: "month", ascending: true), .init(key: "day", ascending: true)]), managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: "month", cacheName: nil)
        do {
          try fetchedResultsController.performFetch()
        }
        catch let error {
          log("fetched failed: \(error)")
        }
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { fetchedResultsController.sections?.count ?? 0 }


    override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      { Quiz.longMonthNames[i] }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      { fetchedResultsController.sections?[i].numberOfObjects ?? 0 }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        let cell = sender.dequeueReusableCell(of: QuizCell.self, withIdentifier: "cell")
        cell.content = fetchedResultsController.object(at: path)
        cell.expandableSubview?.isVisible = sender.isSelected(path)
        return cell
      }


    override func sectionIndexTitles(for sender: UITableView) -> [String]?
      { Quiz.shortMonthNames }


    override func tableView(_ sender: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int
      { index }


    // UITableViewDelegate

    override func tableView(_ sender: UITableView, willSelectRowAt path: IndexPath) -> IndexPath?
      {
        guard let cell = tableView.cellForRow(at: path), cell.isSelected else { return path }
        sender.deselectRow(at: path, animated: true)
        self.tableView(tableView, didDeselectRowAt: path)
        return nil
      }


    override func tableView(_ sender: UITableView, didSelectRowAt path: IndexPath)
      { sender.setExpansionState(true, forCellAt: path) }


    override func tableView(_ sender: UITableView, didDeselectRowAt path: IndexPath)
      { sender.setExpansionState(false, forCellAt: path) }


    // TabBarCompatible

    var tabBarTitle : String
      { "Tests" }


    var tabBarImage : UIImage?
      { UIImage(systemName: "pencil") }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
