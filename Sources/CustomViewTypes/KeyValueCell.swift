/*

*/

import UIKit


class KeyValueCell : GenericTableCell<KeyValueCell.Configuration>
  {
    typealias Content = (key: String, subtitle: String?, value: String?)

    struct Configuration : GenericTableCellConfiguration
      {
        let keyLabel = createLabel()
        let valueLabel = createSecondaryLabel()
        let subtitleLabel = createSecondaryLabel()

        var contentSubview : UIView
          {
            return UIStackView(axis: .vertical, arrangedSubviews: [
              UIStackView(axis: .horizontal, alignment: .firstBaseline, arrangedSubviews: [keyLabel, valueLabel]),
              subtitleLabel,
            ])
          }

        func update(_ cell: GenericTableCell<Self>, for content: Content)
          {
            keyLabel.text = content.key
            subtitleLabel.text = content.subtitle
            subtitleLabel.isHidden = content.subtitle == nil
            valueLabel.text = content.value
          }

        static var selectionStyle : UITableViewCell.SelectionStyle
          { .none }
      }

    var key : String?
      {
        get { content?.key }
        set { content = newValue != nil ? (newValue!, nil, nil) : nil }
      }

    var keyAndValue : (key: String, value: String?)?
      {
        get { content.map { ($0.key, $0.value) } }
        set { content = newValue != nil ? (newValue!.key, nil, newValue!.value) : nil }
      }

    var keyAndSubtitle : (key: String, subtitle: String?)?
      {
        get { content.map { ($0.key, $0.subtitle) } }
        set { content = newValue != nil ? (newValue!.key, newValue!.subtitle, nil) : nil }
      }
  }


class KeyValueDisclosureCell : KeyValueCell
  {
    override func customize()
      {
        super.customize()

        accessoryType = .disclosureIndicator
        selectionStyle = .default
      }
  }
