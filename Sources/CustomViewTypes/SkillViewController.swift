/*

*/

import UIKit
import CoreData
import Schema


class SkillViewController<Model: GameModel> : ObjectViewController<Model.Skill>
  {
    enum Section : Int, CaseIterable
      {
        case description
        case grants
      }


    struct DescriptionCellConfiguration : GenericTableCellConfiguration
      {
        let textView = createMultilineLabel(font: Self.labelFont, color: .label)

        var contentSubview : UIView
          { textView }

        func update(_ cell: GenericTableCell<Self>, for content: String)
          { textView.text = content }

        static var selectionStyle : UITableViewCell.SelectionStyle
          { .none }
      }

    typealias DescriptionCell = GenericTableCell<DescriptionCellConfiguration>


    struct GrantCellConfiguration : GenericTableCellConfiguration
      {
        let nameLabel = createLabel()
        let arcanaLabel = createSecondaryLabel()
        let levelLabel = createSecondaryLabel()

        var contentSubview : UIView
          { UIStackView(axis: .horizontal, spacing: 0, arrangedSubviews: [nameLabel, arcanaLabel, UIView(), levelLabel]) }

        func update(_ cell: GenericTableCell<Self>, for grant: Model.SkillGrant)
          {
            let demon = grant.demon
            nameLabel.text = demon.name
            arcanaLabel.text = ", \(demon.race.name) \(demon.level)"
            levelLabel.text = grant.level > 0 ? "level \(grant.level)" : ""
          }
      }

    typealias GrantCell = GenericTableCell<GrantCellConfiguration>


    private var grantFetchedResultsController : NSFetchedResultsController<Model.SkillGrant>!


    private let cellInfoBySection : [Section: (cellClass: UITableViewCell.Type, identifier: String)] = [
      .description: (DescriptionCell.self, "description"),
      .grants: (GrantCell.self, "grants"),
    ]


    init(skill s: Model.Skill, managedObjectContext c: NSManagedObjectContext)
      {
        super.init(subject: s, managedObjectContext: c)
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: subject.name, subtitle: [subject.type.name, subject.cost.description].compactMap({$0}).joined(separator: ", "))

        let grantFetchRequest = fetchRequest(for: Model.SkillGrant.self)
        grantFetchRequest.sortDescriptors = NSSortDescriptor.with(keyPaths: ["demon.level", "demon.name"], ascending: true)
        grantFetchRequest.predicate = NSPredicate(format: "skill == %@", subject)
        grantFetchedResultsController = NSFetchedResultsController<Model.SkillGrant>(fetchRequest: grantFetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! grantFetchedResultsController.performFetch()

        for info in cellInfoBySection.values {
          tableView.register(info.cellClass, forCellReuseIdentifier: info.identifier)
        }
      }


    // UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        guard let section = Section(rawValue: i) else { preconditionFailure("invalid argument: \(i)") }
        switch section {
          case .description :
            return 1
          case .grants :
            return grantFetchedResultsController.fetchedObjects?.count ?? 0
        }
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        guard let section = Section(rawValue: path.section) else { preconditionFailure("invalid argument: \(path)") }
        guard let cellId = cellInfoBySection[section]?.identifier else { preconditionFailure("TF") }

        switch section {
          case .description :
            let cell = sender.dequeueReusableCell(of: DescriptionCell.self, withIdentifier: cellId)
            cell.content = subject.effect
            return cell
          case .grants :
            let cell = sender.dequeueReusableCell(of: GrantCell.self, withIdentifier: cellId)
            cell.content = grantFetchedResultsController.fetchedObjects?[path.row]
            return cell
        }
      }


    // UITableViewDelegate

    override func tableView(_ tableView: UITableView, titleForHeaderInSection i: Int) -> String?
      {
        cellInfoBySection[Section(rawValue: i)!]?.identifier
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
