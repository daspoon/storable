/*

*/

import UIKit
import CoreData


class EnemyViewController : UITableViewController
  {
    enum Section : Int, CaseIterable
      {
        //case stats
        case resists
        case skills
        case drops
        case misc
      }

    enum Misc : Int, CaseIterable
      {
        case areas
        case card
        case material
        case trait
      }

    let enemies : [Enemy]
    let nameLabel : UILabel
    let levelLabel : UILabel
    let segmentedControl : UISegmentedControl
    var selectedIndex : Int


    init(enemies es: [Enemy], selectedIndex index: Int)
      {
        enemies = es
        nameLabel = UILabel(configuration: {$0.textColor = .label; $0.font = .systemFont(ofSize: 17)})
        levelLabel = UILabel(configuration: {$0.textColor = .secondaryLabel; $0.font = .systemFont(ofSize: 15)})
        segmentedControl = UISegmentedControl(items: [UIImage(systemName: "arrow.backward")!, UIImage(systemName: "arrow.forward")!])
        selectedIndex = index

        super.init(style: .insetGrouped)
      }


    var enemy : Enemy
      { enemies[selectedIndex] }

    // Note: the following should be transient properties of Enemy
    var sortedSkillGrants : [SkillGrant] = []
    var drops : [String] = []


    private func selectEnemy(at index: Int)
      {
        selectedIndex = index

        segmentedControl.setEnabled(0 < index, forSegmentAt: 0)
        segmentedControl.setEnabled(index < enemies.count - 1, forSegmentAt: 1)

        navigationItem.titleView = UILabel(title: enemy.name, subtitle: "Level \(enemy.level)")

        sortedSkillGrants = enemy.skillGrants.sorted(by: {$0 < $1})
        drops = enemy.drops?.components(separatedBy: ", ") ?? []

        tableView.reloadData()
      }


    @objc func page(_ sender: UISegmentedControl)
      { selectEnemy(at: selectedIndex + (sender.selectedSegmentIndex > 0 ? 1 : -1)) }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: "", subtitle: "")

        segmentedControl.isMomentary = true
        segmentedControl.addTarget(self, action: #selector(page(_:)), for: .valueChanged)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: segmentedControl)

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "defaultCell")
        tableView.register(ResistancesCell.self, forCellReuseIdentifier: "resistancesCell")

        tableView.allowsSelection = false

        selectEnemy(at: selectedIndex)
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        switch Section(rawValue: i)! {
            case .resists :
              return 1
            case .skills :
              return sortedSkillGrants.count
            case .drops :
              return drops.count
            case .misc :
              return Misc.allCases.count
        }
      }


    override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      {  "\(Section(rawValue: i)!)" }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        switch Section(rawValue: path.section)! {
          case .resists :
            let resistancesCell = tableView.dequeueReusableCell(of: ResistancesCell.self, withIdentifier: "resistancesCell")
            resistancesCell.content = enemy
            return resistancesCell
          case .skills :
            let skillCell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "defaultCell")
            let grant = sortedSkillGrants[path.row]
            skillCell.keyAndValue = (key: "\(grant.skill.name)", value: grant.level == 0 ? "" : "\(grant.level)")
            return skillCell
          case .drops :
            let dropCell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "defaultCell")
            dropCell.key = drops[path.row]
            return dropCell
          case .misc :
            let cell = sender.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "defaultCell")
            switch Misc(rawValue: path.row)! {
              case .areas :
                cell.keyAndValue = (key: "Areas", value: enemy.areas ?? "?")
              case .card :
                cell.keyAndValue = (key:  "Card", value: enemy.card)
              case .material :
                cell.keyAndValue = (key: "Material", value: enemy.material)
              case .trait :
                cell.keyAndValue = (key: "Trait", value: enemy.trait)
            }
            return cell
        }
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
