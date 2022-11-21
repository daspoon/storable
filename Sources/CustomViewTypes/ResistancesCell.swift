/*

*/

import UIKit


typealias ResistancesCell = GenericTableCell<ResistancesTableCellConfiguration>


struct ResistancesTableCellConfiguration : GenericTableCellConfiguration
  {
    let valueLabels = DataModel.shared.configuration.resistanceElements.map { _ in Self.createSecondaryLabel() }

    static func createIcon(for element: Element) -> UIImageView
      {
        let info = DataModel.shared.configuration.iconInfoForResistanceElement(element)
        let icon = UIImageView(image: UIImage(systemName: info.imageName))
        icon.tintColor = info.tintColor
        icon.contentMode = .scaleAspectFit
        return icon
      }


    var contentSubview : UIView
      {
        UIStackView(arrangedSubviewPairs: zip(DataModel.shared.configuration.resistanceElements, valueLabels).map { (Self.createIcon(for: $0), $1) })
      }


    func update(_ cell: GenericTableCell<Self>, for combatant: Combatant)
      {
        for (i, element) in DataModel.shared.configuration.resistanceElements.enumerated() {
          valueLabels[i].text = combatant.resistance(for: element).description
        }
      }
  }
