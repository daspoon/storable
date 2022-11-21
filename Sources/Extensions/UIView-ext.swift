/*

*/

import UIKit


extension UIView
  {
    public convenience init(width: CGFloat)
      {
        self.init(frame: .zero)
        addConstraint(.init(item: self, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: width))
      }

    public convenience init(wrapping contentView: UIView, insets: UIEdgeInsets = .zero)
      {
        self.init()
        setContentView(contentView, insets: insets)
      }

    public var isVisible : Bool
      {
        get { isHidden == false }
        set { isHidden = newValue == false }
      }

    public func setContentView(_ view: UIView?, insets: UIEdgeInsets = .zero)
      {
        for existing in subviews {
          existing.removeFromSuperview()
        }

        if let view {
          addSubview(view)
          view.translatesAutoresizingMaskIntoConstraints = false
          addConstraints(view.constraintsToFill(in: self, insets: insets))
        }
      }

    public func addSubviews<S: Sequence>(_ views: S) where S.Element : UIView
      {
        for view in views {
          addSubview(view)
        }
      }

    public func constraint(on attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint?
      {
        for constraint in constraints {
          if (constraint.firstItem as? UIView) === self && constraint.firstAttribute == attribute {
            return constraint
          }
        }
        return nil
      }

    public func requiredConstraint(on attribute: NSLayoutConstraint.Attribute, relation: NSLayoutConstraint.Relation = .equal) -> NSLayoutConstraint
      {
        if let constraint = constraint(on: attribute) {
          return constraint
        }
        let constraint = NSLayoutConstraint(item: self, attribute: attribute, relatedBy: relation, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 0)
        addConstraints([constraint])
        return constraint
      }

    public func constraintsToFill(in outer: UIView, insets: UIEdgeInsets = .zero) -> [NSLayoutConstraint]
      {
        let inner = self
        return [
          .init(item: inner, attribute: .top, relatedBy: .equal, toItem: outer, attribute: .top, multiplier: 1, constant: insets.top),
          .init(item: inner, attribute: .left, relatedBy: .equal, toItem: outer, attribute: .left, multiplier: 1, constant: insets.left),
          .init(item: inner, attribute: .bottom, relatedBy: .equal, toItem: outer, attribute: .bottom, multiplier: 1, constant: -insets.bottom),
          .init(item: inner, attribute: .right, relatedBy: .equal, toItem: outer, attribute: .right, multiplier: 1, constant: -insets.right),
        ]
      }

    public func captureImage(size: CGSize? = nil, opaque: Bool? = nil, scale: CGFloat = 0) -> UIImage?
      {
        // adapted from https://stackoverflow.com/a/4334902
        UIGraphicsBeginImageContextWithOptions(size ?? bounds.size, opaque ?? isOpaque, scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        layer.render(in: context)
        return UIGraphicsGetImageFromCurrentImageContext()
      }
  }
