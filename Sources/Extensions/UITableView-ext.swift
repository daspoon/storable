/*

*/

import UIKit


extension UITableView
  {
    public func dequeueReusableCell<T: UITableViewCell>(of: T.Type, withIdentifier id: String) -> T
      {
        guard let cell = dequeueReusableCell(withIdentifier: id) else { preconditionFailure("unknown cell identifier: \(id)") }
        guard let cell = cell as? T else { preconditionFailure("unexpected type for cell identifier '\(id)': \(T.self)") }
        return cell
      }

    public func dequeueReusableCell<T: UITableViewCell>(of: T.Type, withIdentifier id: String, for path: IndexPath) -> T
      {
        guard let cell = dequeueReusableCell(withIdentifier: id, for: path) as? T else { preconditionFailure("unexpected type for cell identifier '\(id)': \(T.self)") }
        return cell
      }

    /// Return the selection state of the given index path.
    public func isSelected(_ path: IndexPath) -> Bool
      {
        switch allowsMultipleSelection {
          case false : return indexPathForSelectedRow == .some(path)
          case true : return indexPathsForSelectedRows?.contains(path) ?? false
        }
      }

    /// Set the visibility of the expandable component of the given cell, if applicable. Intended for use in delegate implementation of row selection events.
    public func setExpansionState(_ expanded: Bool, forCellAt path: IndexPath)
      {
        guard let expandableView = (cellForRow(at: path) as? ExpandableTableCell)?.expandableSubview else { return }
        expandableView.isVisible = expanded
        performBatchUpdates {}
      }
  }
