/*

*/

import UIKit


extension UIStackView
  {
    public convenience init(axis: NSLayoutConstraint.Axis = .horizontal, alignment: Alignment = .fill, distribution: UIStackView.Distribution = .fill, spacing: CGFloat = 8, arrangedSubviews vs: [UIView])
      {
        self.init(arrangedSubviews: vs)
        self.axis = axis
        self.alignment = alignment
        self.distribution = distribution
        self.spacing = spacing
      }

    public convenience init(axis: NSLayoutConstraint.Axis = .horizontal, alignment: Alignment = .fill, distribution: UIStackView.Distribution = .fillEqually, spacing: CGFloat = 8, centered: Bool = true, arrangedSubviewPairs pairs: [(UIView, UIView)])
      {
        self.init(axis: axis, arrangedSubviews: pairs.map { v1, v2 in
          UIStackView(axis: axis.opposite, alignment: .center, arrangedSubviews: [v1, v2])
        })

        self.translatesAutoresizingMaskIntoConstraints = false
        self.distribution = distribution
        self.spacing = spacing

        if centered {
          self.insertArrangedSubview(UIView(), at: 0)
          self.addArrangedSubview(UIView())
        }
      }
  }
