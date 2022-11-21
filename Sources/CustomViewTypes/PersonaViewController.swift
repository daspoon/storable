/*

*/

import UIKit


class PersonaViewController : UITableViewController
  {
    let persona : Persona
    let sortedSkillGrants : [SkillGrant]
    let sortedItemizations : [Itemization]


    enum Section : Int, CaseIterable
      {
        case abilities
        case resistances
        case skills
        case itemizations
      }


    struct SkillCellConfiguration : GenericTableCellConfiguration
      {
        let nameLabel = createLabel()
        let levelLabel = createSecondaryLabel()
        let effectLabel = createMultilineLabel(font: secondaryLabelFont, color: .tintColor)

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, arrangedSubviews: [ nameLabel, UIView(), levelLabel ]),
              UIView(),
              effectLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for grant: SkillGrant)
          {
            nameLabel.text = grant.skill.name
            levelLabel.text = "\(grant.level)"
            effectLabel.text = grant.skill.effect
          }

        var expandableDetailView : UIView?
          { effectLabel }

        func allowExpansion(for grant: SkillGrant) -> Bool
          { grant.skill.effect.isEmpty == false }
      }

    typealias SkillCell = GenericTableCell<SkillCellConfiguration>


    init(persona p: Persona)
      {
        persona = p
        sortedSkillGrants = p.skillGrants.sorted(by: { $0 < $1 })
        sortedItemizations = p.itemizations.sorted(by: { $0 < $1 })

        super.init(style: .insetGrouped)
      }


    @objc func fuse(_ sender: Any?)
      {
        navigationController?.pushViewController(FusionSearchViewController(persona: persona), animated: true)
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: persona.name, subtitle: "\(persona.arcana.name), \(persona.level)")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(fuse(_:)))

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "keyValueCell")
        tableView.register(StatisticsCell.self, forCellReuseIdentifier: "statisticsCell")
        tableView.register(ResistancesCell.self, forCellReuseIdentifier: "resistancesCell")
        tableView.register(SkillCell.self, forCellReuseIdentifier: "skillCell")
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        switch Section(rawValue: i)! {
          case .abilities :
            return 1
          case .resistances :
            return 1
          case .skills :
            return sortedSkillGrants.count
          case .itemizations :
            return sortedItemizations.count
        }
      }


    override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      {
        return "\(Section(rawValue: i)!)"
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        switch Section(rawValue: path.section)! {
          case .abilities :
            let cell = tableView.dequeueReusableCell(of: StatisticsCell.self, withIdentifier: "statisticsCell")
            cell.content = persona
            return cell
          case .resistances :
            let cell = tableView.dequeueReusableCell(of: ResistancesCell.self, withIdentifier: "resistancesCell")
            cell.content = persona
            return cell
          case .skills :
            let cell = sender.dequeueReusableCell(of: SkillCell.self, withIdentifier: "skillCell")
            cell.content = sortedSkillGrants[path.row]
            cell.expandableSubview?.isVisible = tableView.isSelected(path)
            return cell
          case .itemizations :
            let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "keyValueCell")
            let itemization = sortedItemizations[path.row]
            cell.keyAndValue = (key: "\(itemization.name)" + (itemization.rare ? " (rare)" : ""), value: itemization.kind == .skill ? "skill" : "item")
            return cell
        }
      }


    // UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt path: IndexPath) -> IndexPath?
      {
        guard let cell = tableView.cellForRow(at: path), cell.isSelected else { return path }
        tableView.deselectRow(at: path, animated: true)
        self.tableView(tableView, didDeselectRowAt: path)
        return nil
      }


    override func tableView(_ tableView: UITableView, didSelectRowAt path: IndexPath)
      { tableView.setExpansionState(true, forCellAt: path) }


    override func tableView(_ tableView: UITableView, didDeselectRowAt path: IndexPath)
      { tableView.setExpansionState(false, forCellAt: path) }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
