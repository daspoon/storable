/*

*/

import UIKit


public extension UILabel
  {
    public convenience init(configuration: (UILabel) -> Void)
      {
        self.init()
        configuration(self)
      }

    public convenience init(text t: String = "", font f: UIFont? = .systemFont(ofSize: UIFont.systemFontSize), textColor c: UIColor = .label)
      {
        self.init()
        text = t
        font = f
        textColor = c
      }

    public convenience init(title: String, subtitle: String, subtitleColor: UIColor = .secondaryLabel)
      {
        self.init()

        numberOfLines = 2
        textAlignment = .center

        attributedText = .init(string: title, font: .systemFont(ofSize: 19), color: .label)
          + "\n" + .init(string: subtitle, font: .systemFont(ofSize: 15), color: subtitleColor)
      }
  }
