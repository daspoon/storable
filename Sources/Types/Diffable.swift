/*

*/


/// A type which enables calculating differences between its values.

public protocol Diffable
  {
    associatedtype Difference

    func difference(from other: Self) throws -> Difference?
  }


// MARK: --

extension Numeric
  {
    public func difference(from other: Self) throws -> Self?
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
    public func difference(from old: Self) throws -> Difference?
      { try difference(from: old, moduloRenaming: {_ in nil}) }

    /// Calculate the difference between the receiver and another dictionary, modulo a renaming function; this function specifies the source key to which each of the receiver's entries correspond, with nil indicating the same-named entry.
    /// Note that all renamed entries are processed first to allow enable renaming an existing entry while simultaneously adding a new entry with the same name.
    /// The method will throw if a non-nil renaming either does not exist in the source or is assigned to multiple receiver entries.
    public func difference(from old: Self, moduloRenaming rename: (Value) -> Key?) throws -> Difference?
      {
        // Use diff.removed to account for source entries which are not yet correlated with target entries.
        var diff = Difference(removed: old)

        // First process the renamed entries; each represents a potential modification.
        for (newKey, pair) in self.compactMap({k, v in rename(v).map {(k, ($0, v))}}) {
          let (oldKey, newValue) = pair
          guard let oldValue = diff.removed[oldKey] else {
            switch old[oldKey] {
              case .some : throw Exception("renamed key '\(oldKey)' has multiple assignments in target dictionary")
              case .none : throw Exception("renamed key '\(oldKey)' does not exist in source dictionary")
            }
          }
          try newValue.difference(from: oldValue).map { diff.modified[newKey] = $0 }
          diff.removed.removeValue(forKey: oldKey)
        }

        // Then process the entries which are not renamed; each represents either an addition or a potential modification.
        for (key, newValue) in self.compactMap({ rename($1) == nil ? ($0, $1) : nil }) {
          if let oldValue = old[key] {
            try newValue.difference(from: oldValue).map { diff.modified[key] = $0 }
            diff.removed.removeValue(forKey: key)
          }
          else {
            diff.added[key] = newValue
          }
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
