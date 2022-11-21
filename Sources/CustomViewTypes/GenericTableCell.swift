/*

*/

import UIKit


public protocol GenericTableCellConfiguration
  {
    associatedtype Content

    /// Initialize (the component views of) a new instance.
    init()

    /// Install the component views in the cell content view.
    var contentSubview : UIView { get }

    /// Update the component views to reflect the given content.
    func update(_ cell: GenericTableCell<Self>, for content: Content)

    /// Optional view with visibility synced with cell selection state. The default implementation returns nil.
    var expandableDetailView : UIView? { get }

    /// Indicates whether the optional detail view is applicable for the given content. The default implementation returns true.
    func allowExpansion(for content: Content) -> Bool

    /// The insets applied to the contentSubview within the cell contentView.
    static var contentInsets : UIEdgeInsets { get }

    static var labelFont : UIFont { get }
    static var labelColor : UIColor { get }
    static var secondaryLabelFont : UIFont { get }
    static var secondaryLabelColor : UIColor { get }
    static var tertiaryLabelFont : UIFont { get }
    static var tertiaryLabelColor : UIColor { get }

    static var accessoryType : UITableViewCell.AccessoryType { get }
    static var selectionStyle : UITableViewCell.SelectionStyle { get }
  }


extension GenericTableCellConfiguration
  {
    var expandableDetailView : UIView?
      { nil }

    func allowExpansion(for content: Content) -> Bool
      { true }

    static var contentInsets : UIEdgeInsets
      { .init(top: 8, left: 20, bottom: 8, right: 20) }

    static var labelFont : UIFont
      { .systemFont(ofSize: UIFont.labelFontSize) }

    static var labelColor : UIColor
      { .label }

    static var secondaryLabelFont : UIFont
      { .systemFont(ofSize: UIFont.labelFontSize - 2) }

    static var secondaryLabelColor : UIColor
      { .secondaryLabel }

    static var tertiaryLabelFont : UIFont
      { .systemFont(ofSize: UIFont.labelFontSize - 4) }

    static var tertiaryLabelColor : UIColor
      { .tertiaryLabel }

    static var accessoryType : UITableViewCell.AccessoryType
      { .none }

    static var selectionStyle : UITableViewCell.SelectionStyle
      { .default }

    static func createLabel(font: UIFont = labelFont, color: UIColor = labelColor, text: String = "") -> UILabel
      { UILabel {$0.font = font; $0.textColor = color; $0.text = text} }

    static func createSecondaryLabel(text: String = "") -> UILabel
      { createLabel(font: secondaryLabelFont, color: secondaryLabelColor, text: text) }

    static func createTertiaryLabel(text: String = "") -> UILabel
      { createLabel(font: tertiaryLabelFont, color: tertiaryLabelColor, text: text) }

    static func createMultilineLabel(font f: UIFont = labelFont, color c: UIColor = labelColor) -> UILabel
      { UILabel {$0.numberOfLines = 0; $0.font = f; $0.textColor = c} }

    static func createIcon(imageName: String, highlightedImageName: String? = nil, size: CGSize = .init(width: 20, height: 20), tintColor: UIColor = .tintColor) -> UIImageView
      {
        guard let image = UIImage(systemName: imageName) else { preconditionFailure("unknown image name: \(imageName)") }
        let imageView = UIImageView(image: image)
        if let highlightedImageName {
          guard let highlightedImage = UIImage(systemName: highlightedImageName) else { preconditionFailure("unknown image name: \(highlightedImageName)") }
          imageView.highlightedImage = highlightedImage
        }
        imageView.tintColor = tintColor
        imageView.requiredConstraint(on: .width).constant = size.width
        imageView.requiredConstraint(on: .height).constant = size.height
        return imageView
      }
  }


public class GenericTableCell<Configuration: GenericTableCellConfiguration> : UITableViewCell, ExpandableTableCell
  {
    private(set) var configuration : Configuration

    public var content : Configuration.Content?
      {
        didSet {
          guard let content else { return }
          configuration.update(self, for: content)
        }
      }


    /// Enables post-init customization of cell properties such as a accessoryType.
    func customize()
      {
        accessoryType = Configuration.accessoryType
        selectionStyle = Configuration.selectionStyle
      }


    // ExpandableView

    public var expandableSubview : UIView?
      {
        guard let content, let detailView = configuration.expandableDetailView, configuration.allowExpansion(for: content) else { return nil }
        return detailView
      }


    // UITableViewCell

    public override init(style s: UITableViewCell.CellStyle, reuseIdentifier id: String?)
      {
        configuration = Configuration()

        super.init(style: s, reuseIdentifier: id)

        // Install the custom content view
        contentView.setContentView(configuration.contentSubview, insets: Configuration.contentInsets)

        // Allow subclasses to perform one-time customization of this cell.
        customize()

        // Detail view is hidden by default.
        configuration.expandableDetailView?.isHidden = true
      }


    public override func prepareForReuse()
      {
        content = nil

        configuration.expandableDetailView?.isHidden = true

        super.prepareForReuse()
      }


    // NSCoding

    required init?(coder: NSCoder)
      { nil }
  }
