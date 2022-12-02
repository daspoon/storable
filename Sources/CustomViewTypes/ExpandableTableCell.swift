/*

*/

import UIKit


public protocol ExpandableTableCell : UITableViewCell
  {
    /// The descendant view intended to have conditional visibility.
    var expandableSubview : UIView? { get }
  }
