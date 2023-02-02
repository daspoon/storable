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
        /// The keys occurring in the receiver, but not in the other dictionary.
        public var added : [Key] = []
        /// The keys occurring in the other dictionary, but not in the receiver.
        public var removed : [Key] = []
        /// The keys occurring in both dictionaries mapped to the difference between those values.
        public var modified : [Key: Value.Difference] = [:]

        public init(added: [Key] = [], removed: [Key] = [], modified: [Key: Value.Difference] = [:])
          {
            self.added = added
            self.removed = removed
            self.modified = modified
          }

        /// A value representing no difference.
        public static var empty : Self
          { .init() }

        /// Indicates whether or not the value represents no difference.
        public var isEmpty : Bool
          { added.isEmpty && removed.isEmpty && modified.isEmpty }

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
        var diff = Difference()

        // Maintain the source entries which are not yet correlated with target entries.
        var remaining = old

        // First process the renamed entries; each represents a potential modification.
        for (newKey, pair) in self.compactMap({k, v in rename(v).map {(k, ($0, v))}}) {
          let (oldKey, newValue) = pair
          guard let oldValue = remaining[oldKey] else {
            switch old[oldKey] {
              case .some : throw Exception("renamed key '\(oldKey)' has multiple assignments in target dictionary")
              case .none : throw Exception("renamed key '\(oldKey)' does not exist in source dictionary")
            }
          }
          try newValue.difference(from: oldValue).map { diff.modified[newKey] = $0 }
          remaining.removeValue(forKey: oldKey)
        }

        // Then process the entries which are not renamed; each represents either an addition or a potential modification.
        for (key, newValue) in self.compactMap({ rename($1) == nil ? ($0, $1) : nil }) {
          if let oldValue = remaining[key] {
            try newValue.difference(from: oldValue).map { diff.modified[key] = $0 }
            remaining.removeValue(forKey: key)
          }
          else {
            diff.added.append(key)
          }
        }

        diff.removed = Array(remaining.keys)

        return diff
      }
  }

// Enable unit tests...

extension Dictionary.Difference : Equatable where Value.Difference : Equatable
  { }
