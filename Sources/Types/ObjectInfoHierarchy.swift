/*

*/

import Foundation


public enum ObjectInfoHierarchy
  {
    case node(ObjectInfo, [ObjectIdentifier: ObjectInfoHierarchy])

    /// Initialize an instance containing the given list of subclasses and their superclasses, up-to and including root.
    public init(_ objectTypes: [Object.Type]) throws
      {
        self = .node(try ObjectInfo(objectType: Object.self), [:])
        for objectType in objectTypes {
          try add(NSObject.inheritanceChain(from: objectType, includingAncestor: false).reversed())
        }
      }

    /// Insert nodes where necessary for each class in the given inheritance chain, which is ordered from general to specific.
    private mutating func add<S: Sequence>(_ chain: S) throws where S.Element == Object.Type
      {
        if let subclass = chain.first(where: {_ in true}) {
          guard case .node(let objectInfo, var childrenById) = self else { fatalError() }
          precondition(subclass.superclass() as? Object.Type == .some(objectInfo.managedObjectClass))
          let childId = ObjectIdentifier(subclass)
          var child = try childrenById[childId] ?? .node(try ObjectInfo(objectType: subclass), [:])
          try child.add(chain.dropFirst(1))
          childrenById[childId] = child
          self = .node(objectInfo, childrenById)
        }
      }

    /// Perform a post-order traversal where the given function is used to combine the results produced by subnodes (which is an empty list for leaves).
    public func fold<Result>(_ combine: (ObjectInfo, [Result]) throws -> Result) rethrows -> Result
      {
        guard case .node(let objectInfo, let childrenById) = self else { fatalError() }
        return try combine(objectInfo, childrenById.values.map { try $0.fold(combine) })
      }
  }
