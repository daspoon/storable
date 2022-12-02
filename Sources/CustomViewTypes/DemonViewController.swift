/*

*/

import CoreData
import UIKit


class DemonViewController<Model: GameModel> : ObjectViewController<Model.Demon>
  {
    let sortedSkillGrants : [Model.SkillGrant]


    enum Section : Int, CaseIterable
      {
        case statistics
        case affinities
        case elementResistances
        case ailmentResistances
        case skillGrants
      }


    struct StatisticsCellConfiguration<Key: Enumeration, Value: CustomStringConvertible> : GenericTableCellConfiguration
      {
        let valueLabels = Key.allCases.map { _ in Self.createSecondaryLabel() }

        var contentSubview : UIView
          { UIStackView(arrangedSubviewPairs: zip(Key.allCases, valueLabels).map { (Self.createSecondaryLabel(text: $0.shortName), $1) }) }

        func update(_ cell: GenericTableCell<Self>, for values: [Value])
          {
            for i in 0 ..< Key.allCases.count {
              valueLabels[i].text = values[i].description
            }
          }
      }

    typealias StatisticsCell = GenericTableCell<StatisticsCellConfiguration<Model.Statistic, Int>>
    typealias AffinitiesCell = GenericTableCell<StatisticsCellConfiguration<Model.Affinity, Int>>


    struct ResistancesCellConfiguration<Key: Enumeration, Value: CustomStringConvertible> : GenericTableCellConfiguration
      {
        let valueLabels = Key.allCases.map { _ in Self.createSecondaryLabel() }

        var contentSubview : UIView
          { UIStackView(arrangedSubviewPairs: zip(Key.allCases, valueLabels).map { (Self.createIcon(with: $0.iconSpec), $1) }) }

        func update(_ cell: GenericTableCell<Self>, for values: [Value])
          {
            for i in 0 ..< Key.allCases.count {
              valueLabels[i].text = values[i].description
            }
          }
      }

    typealias ElementResistancesCell = GenericTableCell<ResistancesCellConfiguration<Model.Element, Model.Resistance>>
    typealias AilmentResistancesCell = GenericTableCell<ResistancesCellConfiguration<Model.Ailment, Model.Resistance>>


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

        func update(_ cell: GenericTableCell<Self>, for grant: Model.SkillGrant)
          {
            nameLabel.text = grant.skill.name
            levelLabel.text = "\(grant.level)"
            effectLabel.text = grant.skill.effect
          }

        var expandableDetailView : UIView?
          { effectLabel }

        func allowExpansion(for grant: Model.SkillGrant) -> Bool
          { grant.skill.effect.isEmpty == false }
      }

    typealias SkillCell = GenericTableCell<SkillCellConfiguration>


    init(demon d: Model.Demon, managedObjectContext c: NSManagedObjectContext)
      {
        sortedSkillGrants = [] // TODO: d.skillGrants.sorted(by: { $0 < $1 })

        super.init(subject: d, managedObjectContext: c)
      }


    @objc func fuse(_ sender: Any?)
      {
        log("todo")
        // navigationController?.pushViewController(FusionSearchViewController(persona: persona), animated: true)
      }


    // UIViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: subject.name, subtitle: "\(subject.race.name), \(subject.level)")

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(fuse(_:)))

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "keyValueCell")
        tableView.register(StatisticsCell.self, forCellReuseIdentifier: "statisticsCell")
        tableView.register(AffinitiesCell.self, forCellReuseIdentifier: "affinitiesCell")
        tableView.register(ElementResistancesCell.self, forCellReuseIdentifier: "elementResistancesCell")
        tableView.register(AilmentResistancesCell.self, forCellReuseIdentifier: "ailmentResistancesCell")
        tableView.register(SkillCell.self, forCellReuseIdentifier: "skillCell")
      }


    // UITableViewDataSource

    override func numberOfSections(in sender: UITableView) -> Int
      { Section.allCases.count }


    override func tableView(_ sender: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        switch Section(rawValue: i)! {
          case .statistics :
            return 1
          case .affinities :
            return 1
          case .elementResistances :
            return 1
          case .ailmentResistances :
            return 1
          case .skillGrants :
            return sortedSkillGrants.count
        }
      }


    override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      {
        return "\(Section(rawValue: i)!)"
      }


    override func tableView(_ sender: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        switch Section(rawValue: path.section)! {
          case .statistics :
            let cell = tableView.dequeueReusableCell(of: StatisticsCell.self, withIdentifier: "statisticsCell")
            cell.content = subject.statistics
            return cell
          case .affinities :
            let cell = tableView.dequeueReusableCell(of: AffinitiesCell.self, withIdentifier: "affinitiesCell")
            cell.content = subject.affinities
            return cell
          case .elementResistances :
            let cell = tableView.dequeueReusableCell(of: ElementResistancesCell.self, withIdentifier: "elementResistancesCell")
            cell.content = subject.elementResistances
            return cell
          case .ailmentResistances :
            let cell = tableView.dequeueReusableCell(of: AilmentResistancesCell.self, withIdentifier: "ailmentResistancesCell")
            cell.content = subject.ailmentResistances
            return cell
          case .skillGrants :
            let cell = sender.dequeueReusableCell(of: SkillCell.self, withIdentifier: "skillCell")
            cell.content = sortedSkillGrants[path.row]
            cell.expandableSubview?.isVisible = tableView.isSelected(path)
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
