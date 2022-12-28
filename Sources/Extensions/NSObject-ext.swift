/*

*/

import Foundation


extension NSObject
  {
    /// A tree of classes representing a (partial) inheritance hierarchy. The tree is partial in the sense that not all descendant classes are members, but all ancestors of all members are also members.
    ///
    public enum InheritanceHierarchy<Root: NSObject>
      {
        case node(Root.Type, [ObjectIdentifier: InheritanceHierarchy<Root>])

        mutating func add<S: Sequence>(_ chain: S) where S.Element == Root.Type
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

        public func fold<Result>(_ combine: (Root.Type, [Result]) -> Result) -> Result
          {
            guard case .node(let type, let childrenById) = self else { fatalError("as if") }
            return combine(type, childrenById.values.map { $0.fold(combine) })
          }
      }


    /// Return the inheritance hierarchy for the given base class and list of subclasses.
    public static func inheritanceHierarchy<Base: NSObject>(for base: Base.Type = Base.self, with subclasses: [Base.Type]) -> InheritanceHierarchy<Base>
      {
        var hierarchy : InheritanceHierarchy<Base> = .node(base, [:])
        for subclass in subclasses {
          hierarchy.add(inheritanceChain(from: subclass, includingAncestor: false).reversed())
        }
        return hierarchy
      }


    /// Return the sequence of classes between given descendant and ancestor classes, inclusive.
    public static func inheritanceChain<Root: NSObject>(from descendant: Root.Type, to ancestor: Root.Type = Root.self, includingDescendant: Bool = true, includingAncestor: Bool = true) -> AnyIterator<Root.Type>
      {
        var next = includingDescendant ? descendant : (descendant.superclass() as? Root.Type)
        return AnyIterator {
          defer { next = next?.superclass() as? Root.Type }
          return includingAncestor || next != .some(ancestor) ? next : nil
        }
      }
  }
