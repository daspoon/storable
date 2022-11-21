/*

*/

import UIKit
import CoreData


class SkillViewController : UITableViewController
  {
    enum Section : Int, CaseIterable
      {
        case description = 0
        case personas = 1
        case enemies = 2
        case itemization = 3
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


    struct PersonaGrantCellConfiguration : GenericTableCellConfiguration
      {
        let nameLabel = createLabel()
        let arcanaLabel = createSecondaryLabel()
        let levelLabel = createSecondaryLabel()

        var contentSubview : UIView
          { UIStackView(axis: .horizontal, spacing: 0, arrangedSubviews: [nameLabel, arcanaLabel, UIView(), levelLabel]) }

        func update(_ cell: GenericTableCell<Self>, for grant: SkillGrant)
          {
            let persona = grant.wielder as! Persona
            nameLabel.text = persona.name
            arcanaLabel.text = ", \(persona.arcana.name) \(persona.level)"
            levelLabel.text = grant.level > 0 ? "level \(grant.level)" : ""
          }
      }

    typealias PersonaCell = GenericTableCell<PersonaGrantCellConfiguration>


    let skill : Skill

    private var grantFetchedResultsController : NSFetchedResultsController<SkillGrant>!
    private var itemizationFetchedResultsController : NSFetchedResultsController<Itemization>!
    private var personaGrants : [SkillGrant] = []
    private var enemyGrants : [SkillGrant] = []


    private let cellInfoBySection : [Section: (cellClass: UITableViewCell.Type, identifier: String)] = [
      .description: (DescriptionCell.self, "description"),
      .personas: (PersonaCell.self, "personas"),
      .enemies: (KeyValueCell.self, "enemies"),
      .itemization: (KeyValueCell.self, "itemization"),
    ]


    init(skill s: Skill)
      {
        skill = s

        super.init(style: .insetGrouped)
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: skill.name, subtitle: [skill.element.description, skill.formattedCost].compactMap({$0}).joined(separator: ", "))

        let grantFetchRequest = DataModel.fetchRequest(for: SkillGrant.self)
        grantFetchRequest.sortDescriptors = NSSortDescriptor.with(keyPaths: ["wielder.level", "wielder.name"], ascending: true)
        grantFetchRequest.predicate = NSPredicate(format: "skill == %@", skill)
        grantFetchedResultsController = NSFetchedResultsController<SkillGrant>(fetchRequest: grantFetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! grantFetchedResultsController.performFetch()

        personaGrants = grantFetchedResultsController.fetchedObjects!.filter {$0.wielder is Persona}
        enemyGrants = grantFetchedResultsController.fetchedObjects!.filter {$0.wielder is Enemy}

        let itemizationFetchRequest = DataModel.fetchRequest(for: Itemization.self)
        itemizationFetchRequest.sortDescriptors = NSSortDescriptor.with(keyPaths: ["persona.name"])
        itemizationFetchRequest.predicate = NSPredicate(format: "skill == %@", skill)
        itemizationFetchedResultsController = NSFetchedResultsController<Itemization>(fetchRequest: itemizationFetchRequest, managedObjectContext: DataModel.shared.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        try! itemizationFetchedResultsController.performFetch()

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
          case .personas :
            return personaGrants.count
          case .enemies :
            return enemyGrants.count
          case .itemization :
            return itemizationFetchedResultsController.sections![0].numberOfObjects
        }
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        guard let section = Section(rawValue: path.section) else { preconditionFailure("invalid argument: \(path)") }
        guard let cellId = cellInfoBySection[section]?.identifier else { preconditionFailure("TF") }

        switch section {
          case .description :
            let cell = sender.dequeueReusableCell(of: DescriptionCell.self, withIdentifier: cellId)
            cell.content = skill.effect
            return cell
          case .personas :
            let cell = sender.dequeueReusableCell(of: PersonaCell.self, withIdentifier: cellId)
            cell.content = personaGrants[path.row]
            return cell
          case .enemies :
            let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: cellId)
            let grant = enemyGrants[path.row]
            cell.key = grant.wielder.name
            return cell
          case .itemization :
            let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: cellId)
            let itemization = itemizationFetchedResultsController.fetchedObjects![path.row]
            cell.keyAndValue = (key: itemization.persona.name, value: itemization.rare ? "rare" : "")
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
