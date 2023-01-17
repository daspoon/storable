/*

*/

import Foundation


/// A tree of classes representing a (partial) inheritance hierarchy. The tree is partial in the sense that not all descendant classes are members, but all ancestors of all members are also members.

public enum InheritanceHierarchy<Root: NSObject>
  {
    case node(Root.Type, [ObjectIdentifier: InheritanceHierarchy<Root>])

    /// Initialize an instance containing the given list of subclasses and their superclasses, up-to and including root.
    public init(root: Root.Type = Root.self, containing subclasses: [Root.Type])
      {
        self = .node(root, [:])
        for subclass in subclasses {
          add(NSObject.inheritanceChain(from: subclass, includingAncestor: false).reversed())
        }
      }

    /// Insert nodes for each class in the given inheritance chain, which is ordered from general to specific.
    private mutating func add<S: Sequence>(_ chain: S) where S.Element == Root.Type
      {
        if let subclass = chain.first(where: {_ in true}) {
          guard case .node(let type, var childrenById) = self else { fatalError("as if") }
          precondition(subclass.superclass() as? Root.Type == .some(type), "invalid argument")
          let childId = ObjectIdentifier(subclass)
          var child = childrenById[childId] ?? .node(subclass, [:])
          child.add(chain.dropFirst(1))
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
