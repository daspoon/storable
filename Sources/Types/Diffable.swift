/*

*/


/// A type which enables calculating differences between its values.

public protocol Diffable
  {
    associatedtype Difference

    func difference(from other: Self) -> Difference?
  }


// MARK: --

extension Numeric
  {
    public func difference(from other: Self) -> Self?
      {
        let delta = self - other
        return delta != 0 ? delta : nil
      }
  }

extension Int : Diffable {}


// MARK: --

extension Dictionary : Diffable where Value : Diffable
  {
    /// Maintains the result of the difference(from:) method.
    public struct Difference
      {
        /// The entries occurring in the receiver, but not in the other dictionary.
        public var added : [Key: Value] = [:]
        /// The entries occurring in the other dictionary, but not in the receiver.
        public var removed : [Key: Value] = [:]
        /// The keys occurring in both dictionaries mapped to the difference between those values.
        public var modified : [Key: Value.Difference] = [:]

        public init(added: [Key: Value] = [:], removed: [Key: Value] = [:], modified: [Key: Value.Difference] = [:])
          {
            self.added = added
            self.removed = removed
            self.modified = modified
          }

        /// Return the receiver's content after exchanging the roles of added and removed.
        public var inverse : Difference
          { .init(added: removed, removed: added, modified: modified) }
      }

    /// Calculate the difference between the receiver and another dictionary.
    public func difference(from old: Self) -> Difference?
      {
        var diff = Difference()

        // All entries of self are either added or modified...
        for (key, newValue) in self {
          if let oldValue = old[key] {
            if let delta = newValue.difference(from: oldValue) {
              diff.modified[key] = delta
            }
          }
          else {
            diff.added[key] = newValue
          }
        }

        // The removed entries are those in old but not in self...
        for (key, oldInfo) in old {
          guard self[key] == nil else { continue }
          diff.removed[key] = oldInfo
        }

        return diff
      }
  }

// Enable unit tests...

extension Dictionary.Difference : Equatable where Value : Equatable, Value.Difference : Equatable
  {
    public static func == (lhs: Self, rhs: Self) -> Bool
      { lhs.added == rhs.added && lhs.removed == rhs.removed && lhs.modified == rhs.modified }
  }
