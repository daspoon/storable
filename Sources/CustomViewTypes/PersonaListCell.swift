/*

*/

import UIKit


class PersonaListCell : GenericTableCell<PersonaListCell.Configuration>
  {
    struct Configuration : GenericTableCellConfiguration
      {
        struct Options : OptionSet
          {
            let rawValue : UInt
            init(rawValue v: UInt)
              { rawValue = v }

            static let showArcana     = Self(rawValue: 1 << 0)
            static let showDisclosure = Self(rawValue: 1 << 1)
          }

        static let registryImage = UIImage(systemName: "book")!

        let nameLabel = createLabel()
        let descriptionLabel = createSecondaryLabel()
        let compendiumButton : UIButton = {
          let button = UIButton.systemButton(with: registryImage, target: nil, action: nil)
          button.contentMode = .scaleAspectFit
          return button
        }()

        var contentSubview : UIView
          { UIStackView(axis: .horizontal, spacing: 0, arrangedSubviews: [nameLabel, descriptionLabel, UIView(), compendiumButton]) }

        func update(_ cell: GenericTableCell<Self>, for content: (persona: Persona, options: Options))
          {
            nameLabel.text = content.persona.name
            descriptionLabel.text = "," + (content.options.contains(.showArcana) ? " \(content.persona.arcana.name)" : "") + " \(content.persona.level)"
            compendiumButton.tintColor = content.persona.captured ? .registeredColor : .unregisteredColor

            cell.accessoryType = content.options.contains(.showDisclosure) ? .disclosureIndicator : .none
          }
      }


    @objc func capture(_ sender: UIButton)
      {
        guard let content, !content.persona.captured else { return }
        content.persona.captured = true
        configuration.compendiumButton.tintColor = content.persona.captured ? .registeredColor : .unregisteredColor
        NotificationCenter.default.post(name: .dataStoreNeedsSave, object: nil)
      }


    override func customize()
      {
        super.customize()

        configuration.compendiumButton.addTarget(self, action: #selector(capture(_:)), for: .primaryActionTriggered)
      }
  }
