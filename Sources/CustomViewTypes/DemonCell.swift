/*

*/

import UIKit
import Schema


/// DemonCell is used to present a brief summary of a demon in a table view cell.
/// 
class DemonCell<Model: GameModel> : GenericTableCell<DemonCell.Configuration>
  {
    struct Configuration : GenericTableCellConfiguration
      {
        struct Options : OptionSet
          {
            let rawValue : UInt
            init(rawValue v: UInt)
              { rawValue = v }

            static var showRace : Options { Self(rawValue: 1 << 0) }
            static var showDisclosure : Options { Self(rawValue: 1 << 1) }
          }

        static var registryImage : UIImage { UIImage(systemName: "book")! }

        let nameLabel = createLabel()
        let descriptionLabel = createSecondaryLabel()
        let compendiumButton : UIButton = {
          let button = UIButton.systemButton(with: registryImage, target: nil, action: nil)
          button.contentMode = .scaleAspectFit
          return button
        }()

        var contentSubview : UIView
          { UIStackView(axis: .horizontal, spacing: 0, arrangedSubviews: [nameLabel, descriptionLabel, UIView(), compendiumButton]) }

        func update(_ cell: GenericTableCell<Self>, for content: (demon: Model.Demon, options: Options))
          {
            nameLabel.text = content.demon.name
            descriptionLabel.text = "," + (content.options.contains(.showRace) ? " \(content.demon.race.name)" : "") + " \(content.demon.level)"
            compendiumButton.tintColor = content.demon.captured ? .registeredColor : .unregisteredColor

            cell.accessoryType = content.options.contains(.showDisclosure) ? .disclosureIndicator : .none
          }
      }


    @objc func capture(_ sender: UIButton)
      {
        guard let content, !content.demon.captured else { return }
        content.demon.captured = true
        configuration.compendiumButton.tintColor = content.demon.captured ? .registeredColor : .unregisteredColor
        NotificationCenter.default.post(name: .dataStoreNeedsSave, object: nil)
      }


    override func customize()
      {
        super.customize()

        configuration.compendiumButton.addTarget(self, action: #selector(capture(_:)), for: .primaryActionTriggered)
      }
  }
