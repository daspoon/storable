/*

*/

import UIKit


typealias StatisticsCell = GenericTableCell<StatisticsTableCellConfiguration>


struct StatisticsTableCellConfiguration : GenericTableCellConfiguration
  {
    let valueLabels = DataModel.shared.configuration.abilities.map { _ in Self.createLabel(font: Self.secondaryLabelFont) }


    var contentSubview : UIView
      {
        return UIStackView(arrangedSubviewPairs: zip(DataModel.shared.configuration.abilities, valueLabels).map { (Self.createSecondaryLabel(text: $0), $1) })
      }


    func update(_ cell: GenericTableCell<Self>, for combatant: Combatant)
      {
        for (i, ability) in DataModel.shared.configuration.abilities.enumerated() {
          valueLabels[i].text = combatant.value(for: ability).description
        }
      }
  }
