/*

*/

import CoreData


extension NSFetchedResultsController
  {
    @objc public func sectionedIndexPath(after path: IndexPath) -> IndexPath?
      {
        guard let sections = sections else { return nil }

        if path.row + 1 < sections[path.section].numberOfObjects {
          return IndexPath(row: path.row + 1, section: path.section)
        }

        if path.section + 1 < sections.count {
          return IndexPath(row: 0, section: path.section + 1)
        }

        return nil
      }
  }
