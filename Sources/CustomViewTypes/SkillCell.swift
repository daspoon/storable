/*

*/

import UIKit


typealias SkillCell<Model: GameModel> = GenericTableCell<SkillCellConfiguration<Model>>


struct SkillCellConfiguration<Model: GameModel> : GenericTableCellConfiguration
  {
    struct Option : OptionSet
      {
        let rawValue : Int
        init(rawValue i: Int) { rawValue = i }
        static var type   : Self { .init(rawValue: 1 << 0) }
        static var cost   : Self { .init(rawValue: 1 << 1) }
        static var effect : Self { .init(rawValue: 1 << 2) }
      }


    let nameLabel = createLabel()
    let rightLabel = createSecondaryLabel()
    let effectLabel = createTertiaryLabel()


    var contentSubview : UIView
      {
        return UIStackView(axis: .vertical, arrangedSubviews: [
          UIStackView(axis: .horizontal, alignment: .firstBaseline, arrangedSubviews: [nameLabel, UIView(), rightLabel]),
          effectLabel,
        ])
      }


    func update(_ cell: GenericTableCell<Self>, for state: (skill: Model.Skill, options: [Option]))
      {
        nameLabel.text = state.skill.name
        rightLabel.text = [(state.options.contains(.type) ? state.skill.type.name : nil), (state.options.contains(.cost) ? state.skill.cost.description : nil)].compactMap({$0}).joined(separator: ", ")
        effectLabel.text = state.options.contains(.effect) ? state.skill.effect : ""
        effectLabel.isHidden = state.options.contains(.effect) == false
      }


    static var accessoryType : UITableViewCell.AccessoryType
      { .disclosureIndicator }
  }
