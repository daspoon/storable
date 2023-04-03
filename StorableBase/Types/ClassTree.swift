/*

  Created by David Spooner

*/

import Foundation


/// A tree of classes representing a (partial) inheritance hierarchy. The tree is partial in the sense that not all descendant classes are members, but all ancestors of all members are also members.

public enum ClassTree<Root: NSObject>
  {
    case node(Root.Type, [ObjectIdentifier: ClassTree<Root>])

    /// Initialize an instance containing only the root class.
    public init(root: Root.Type = Root.self)
      {
        self = .node(root, [:])
      }

    /// For convenience, initialize an instance containing the given list of subclasses and their superclasses up-to and including root.
    public init(root: Root.Type = Root.self, containing subclasses: [Root.Type] = [], onAdd f: (Root.Type) throws -> Void = {_ in }) rethrows
      {
        self = .node(root, [:])
        for subclass in subclasses {
          try add(subclass, onAdd: f)
        }
      }

    /// Return the sequence of classes between given descendant and ancestor classes, inclusive.
    private static func inheritanceChain(from descendant: Root.Type, to ancestor: Root.Type = Root.self, includingDescendant: Bool = true, includingAncestor: Bool = true) -> AnyIterator<Root.Type>
      {
        var next = includingDescendant ? descendant : (descendant.superclass() as? Root.Type)
        return AnyIterator {
          defer { next = next?.superclass() as? Root.Type }
          return includingAncestor || next != .some(ancestor) ? next : nil
        }
      }

    /// Insert nodes for the given class and its superclasses if necessary.
    public mutating func add(_ type: Root.Type, onAdd f: (Root.Type) throws -> Void = {_ in }) rethrows
      {
        let chain = Self.inheritanceChain(from: type, includingAncestor: false).reversed()
        try add(chain, onAdd: f)
      }

    /// Insert nodes for each class in the given inheritance chain, which is ordered from general to specific.
    private mutating func add<S: Sequence>(_ chain: S, onAdd f: (Root.Type) throws -> Void = {_ in }) rethrows where S.Element == Root.Type
      {
        if let subclass = chain.first(where: {_ in true}) {
          guard case .node(let type, var childrenById) = self else { fatalError("as if") }
          precondition(subclass.superclass() as? Root.Type == .some(type), "invalid argument")
          let childId = ObjectIdentifier(subclass)
          let existingChild = childrenById[childId]
          if existingChild == nil { try f(subclass) }
          var child = existingChild ?? .node(subclass, [:])
          try child.add(chain.dropFirst(1), onAdd: f)
          childrenById[childId] = child
          self = .node(type, childrenById)
        }
      }

    /// Perform a post-order traversal where the given function is used to combine the results produced by subnodes (which is an empty list for leaves).
    public func fold<Result>(_ combine: (Root.Type, [Result]) throws -> Result) rethrows -> Result
      {
        guard case .node(let type, let childrenById) = self else { fatalError("as if") }
        return try combine(type, childrenById.values.map { try $0.fold(combine) })
      }
  }
