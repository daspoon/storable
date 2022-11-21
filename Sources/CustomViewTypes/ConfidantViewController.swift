/*

*/

import UIKit
import CoreData


class ConfidantViewController : UITableViewController
  {
    enum Section : Int, CaseIterable
      {
        case location
        case advancement
        case persona
        case talents
        case hangouts
        case gifts
      }


    struct AdvancementCellConfiguration : GenericTableCellConfiguration
      {
        let rankLabel = createLabel(font: secondaryLabelFont)
        let bonusLabel = createLabel(font: secondaryLabelFont)
        let requirementsLabel = createMultilineLabel(font: secondaryLabelFont, color: secondaryLabelColor)
        let dialogLabel = createMultilineLabel(font: secondaryLabelFont, color: .tintColor)

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, alignment: .center, spacing: 0, arrangedSubviews: [
                rankLabel, UIView(), bonusLabel,
              ]),
              requirementsLabel,
              UIView(),
              dialogLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for advancement: Confidant.Advancement)
          {
            rankLabel.text = "Rank \(advancement.rank)" + (advancement.unlock.map({" - \u{1F512} " + printGameDate($0)}) ?? "")
            bonusLabel.text = advancement.bonus
            requirementsLabel.text = [advancement.prerequisite, advancement.restriction].compactMap({$0.map{$0 + "."}}).joined(separator: " ")

            dialogLabel.text = advancement.dialogue.map { (lines: [String]) in
              let indentedNumberedLines = lines.enumerated().map({i, s in "  Q\(i+1): " + s})
              return (["Optimal Responses:"] + indentedNumberedLines).joined(separator: "\n")
            }
          }

        var expandableDetailView : UIView?
          { dialogLabel }


        func allowExpansion(for advancement: Confidant.Advancement) -> Bool
          { advancement.dialogue != nil }
      }

    typealias AdvancementCell = GenericTableCell<AdvancementCellConfiguration>


    struct HangoutCellConfiguration : GenericTableCellConfiguration
      {
        let venueLabel : UILabel = createLabel()
        let availableLabel : UILabel = createSecondaryLabel()
        let bonusLabel : UILabel = createSecondaryLabel()
        let requirementLabel : UILabel = createMultilineLabel(font: secondaryLabelFont, color: secondaryLabelColor)
        let dialogLabel : UILabel = createMultilineLabel(font: secondaryLabelFont, color: .tintColor)

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, spacing: 4, arrangedSubviews: [
              UIStackView(axis: .horizontal, alignment: .center, spacing: 8, arrangedSubviews: [
                venueLabel, availableLabel, UIView(), bonusLabel,
              ]),
              requirementLabel,
              UIView(),
              dialogLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for hangout: Confidant.Hangout)
          {
            venueLabel.text = hangout.venue
            availableLabel.text = hangout.available.map({printGameDateRange($0)})
            bonusLabel.text = hangout.bonus
            requirementLabel.text = hangout.requirement
            requirementLabel.isHidden = hangout.requirement == nil
            dialogLabel.text = hangout.dialog.map { (lines: [String]) in
              let indentedNumberedLines = lines.enumerated().map({i, s in "  Q\(i+1): " + s})
              return (["Optimal Responses:"] + indentedNumberedLines).joined(separator: "\n")
            }
          }

        var expandableDetailView : UIView?
          { dialogLabel }

        func allowExpansion(for hangout: Confidant.Hangout) -> Bool
          { (hangout.dialog?.count ?? 0) > 0 }
      }

    typealias HangoutCell = GenericTableCell<HangoutCellConfiguration>


    struct TalentCellConfiguration : GenericTableCellConfiguration
      {
        let nameLabel = createLabel()
        let rankLabel = createSecondaryLabel()
        let effectLabel = createMultilineLabel(font: secondaryLabelFont, color: .tintColor)

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, arrangedSubviews: [ nameLabel, UIView(), rankLabel ]),
              UIView(),
              effectLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for talent: Confidant.Talent)
          {
            nameLabel.text = talent.name
            rankLabel.text = "rank \(talent.rank)"
            effectLabel.text = talent.effect
          }

        var expandableDetailView : UIView?
          { effectLabel }
      }

    typealias TalentCell = GenericTableCell<TalentCellConfiguration>


    let confidant : Confidant
    let giftEffects : [GiftEffect]
    let visibleSections : [Section]


    init(confidant c: Confidant)
      {
        confidant = c
        giftEffects = try! DataModel.shared.managedObjectContext.fetch(DataModel.fetchRequest(for: GiftEffect.self, predicate: .init(format: "confidant = %@", c), sortDescriptors: [.init(key: "bonus", ascending: false)]))

        visibleSections = []
          + (c.location != nil ? [.location] : [])
          + (c.persona != nil ? [.persona] : [])
          + [.advancement]
          + [.talents]
          + (c.hangouts.count > 0 ? [.hangouts] : [])
          + (giftEffects.count > 0 ? [.gifts] : [])

        super.init(style: .insetGrouped)
      }


    // UITableViewController

    override func viewDidLoad()
      {
        super.viewDidLoad()

        navigationItem.titleView = UILabel(title: confidant.name, subtitle: confidant.arcanum.name.removingSuffix(" P"))

        tableView.register(KeyValueCell.self, forCellReuseIdentifier: "locationCell")
        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "personaCell")
        tableView.register(TalentCell.self, forCellReuseIdentifier: "talentCell")
        tableView.register(AdvancementCell.self, forCellReuseIdentifier: "advancementCell")
        tableView.register(HangoutCell.self, forCellReuseIdentifier: "hangoutCell")
        tableView.register(KeyValueDisclosureCell.self, forCellReuseIdentifier: "giftCell")
      }


    // UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int
      { visibleSections.count }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection i: Int) -> Int
      {
        switch visibleSections[i] {
          case .location :
            return 1
          case .persona :
            return 1
          case .talents :
            return confidant.talents.count
          case .advancement :
            return confidant.advancements.count
          case .hangouts :
            return confidant.hangouts.count
          case .gifts :
            return giftEffects.count
        }
      }


    override func tableView(_ tableView: UITableView, cellForRowAt path: IndexPath) -> UITableViewCell
      {
        switch visibleSections[path.section] {
          case .location :
            let cell = tableView.dequeueReusableCell(of: KeyValueCell.self, withIdentifier: "locationCell")
            cell.key = confidant.location ?? "?"
            return cell
          case .persona :
            let cell = tableView.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "personaCell")
            cell.key = confidant.persona?.name ?? "?"
            return cell
          case .talents :
            let cell = tableView.dequeueReusableCell(of: TalentCell.self, withIdentifier: "talentCell")
            cell.content = confidant.talents[path.row]
            cell.expandableSubview?.isVisible = tableView.isSelected(path)
            return cell
          case .advancement :
            let cell = tableView.dequeueReusableCell(of: AdvancementCell.self, withIdentifier: "advancementCell")
            cell.content = confidant.advancements[path.row]
            cell.expandableSubview?.isVisible = tableView.isSelected(path)
            return cell
          case .gifts :
            let cell = tableView.dequeueReusableCell(of: KeyValueDisclosureCell.self, withIdentifier: "giftCell")
            let effect = giftEffects[path.row]
            cell.keyAndValue = (key: effect.gift.name, value: "+\(effect.bonus)")
            return cell
          case .hangouts :
            let cell = tableView.dequeueReusableCell(of: HangoutCell.self, withIdentifier: "hangoutCell")
            cell.content = confidant.hangouts[path.row]
            cell.expandableSubview?.isVisible = tableView.isSelected(path)
            return cell
        }
      }


    // UITableViewDelegate

    override func tableView(_ sender: UITableView, titleForHeaderInSection i: Int) -> String?
      { "\(visibleSections[i])" }


    override func tableView(_ tableView: UITableView, willSelectRowAt path: IndexPath) -> IndexPath?
      {
        guard let cell = tableView.cellForRow(at: path), cell.isSelected else { return path }
        tableView.deselectRow(at: path, animated: true)
        self.tableView(tableView, didDeselectRowAt: path)
        return nil
      }


    override func tableView(_ tableView: UITableView, didSelectRowAt path: IndexPath)
      {
        switch visibleSections[path.section] {
          case .persona :
            navigationController?.pushViewController(PersonaViewController(persona: confidant.persona!), animated: true)
          case .gifts :
            navigationController?.pushViewController(GiftViewController(gift: giftEffects[path.row].gift), animated: true)
          default :
            tableView.setExpansionState(true, forCellAt: path)
        }
      }


    override func tableView(_ tableView: UITableView, didDeselectRowAt path: IndexPath)
      { tableView.setExpansionState(false, forCellAt: path) }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
