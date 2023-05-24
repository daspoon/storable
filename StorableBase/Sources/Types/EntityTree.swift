/*

  Created by David Spooner

*/

import CoreData


/// *EntityTree* is a tree of  *ManagedObject* subclasses ordered by inheritance.
/// The root node corresponds to *ManagedObject* itself and maintains a mapping of defined entity names to internal nodes.
/// Each internal node corresponds to a defined entity and retains the associated metadata, CoreData descriptor and property registry for that entity.
/// Instances are created in an incomplete state in which nodes can be added, but no associated data is accessible.
/// Invoking the *complete* method makes associated data available and prevents further modifications.

@dynamicMemberLookup
public class EntityTree
  {
    /// The managed object class specified in initialization.
    public let objectType : ManagedObject.Type

    /// The subnodes indexed by object identifier.
    public private(set) var childrenById : [ObjectIdentifier: EntityTree] = [:]

    /// Maintains the level and associated data of each node.
    private var state : State
    private enum State
      {
        case incompleteRoot([String: EntityTree])
        case completeRoot([String: EntityTree])
        case incompleteEntity(Entity)
        case completeEntity(Entity, NSEntityDescription, [String: Property])
      }


    /// Create a new tree from a list of *ManagedObject* subclasses.
    internal init(objectTypes types: [ManagedObject.Type]) throws
      {
        objectType = ManagedObject.self
        state = .incompleteRoot([:])

        for type in types {
          try self.addObjectType(type)
        }
      }


    /// Create an internal node for a concrete *ManagedObject* subclass.
    private init(entity: Entity)
      {
        objectType = entity.managedObjectClass
        state = .incompleteEntity(entity)
      }


    /// Insert nodes for the given class and its superclasses where necessary.
    internal func addObjectType(_ givenType: ManagedObject.Type, entity: Entity? = nil) throws
      {
        guard case .incompleteRoot(var nodeMap) = state else { preconditionFailure("invalid invocation") }

        // Create an entity descriptor if necessary.
        let givenEntity = try entity ?? (try Entity(objectType: givenType))

        // Add nodes where necessary for the classes strictly between the root and the given class.
        var node = self
        for type in NSObject.inheritanceChain(from: givenType, to: ManagedObject.self, includingDescendant: true, includingAncestor: false).reversed() {
          let typeId = ObjectIdentifier(type)
          var child = node.childrenById[typeId]
          if child == nil {
            let entity = type == givenType ? givenEntity : try Entity(objectType: type)
            guard nodeMap[entity.name] == nil else { throw Exception("duplicate definition of entity '\(entity.name)' by \(type)") }
            child = EntityTree(entity: entity)
            node.childrenById[typeId] = child
            nodeMap[entity.name] = child
          }
          node = child!
        }

        // Update our sate to reflect the insertions
        state = .incompleteRoot(nodeMap)
      }


    /// Complete each node by assigning an *NSEntityDescription* which reflects inhertiance and a mapping of names to *Property* instances including defined and inherited properties.
    internal func complete() throws -> [String: EntityTree]
      {
        guard case .incompleteRoot(let nodeMap) = state else { preconditionFailure("invalid invocation") }

        // Note that propertiesByName is built top-down, while entityDescription is built bottom-up...
        for child in childrenById.values {
          _ = try child.complete(inheritedProperties: [:])
        }

        state = .completeRoot(nodeMap)

        return nodeMap
      }


    private func complete(inheritedProperties: [String: Property]) throws -> NSEntityDescription
      {
        guard case .incompleteEntity(let entity) = state else { preconditionFailure("invalid invocation") }

        // Create the combined dictionary of both defined and inherited properties
        let properties : [String: Property] = try inheritedProperties.combining(
          entity.attributes.map { ($0, .attribute($1)) } +
          entity.relationships.map { ($0, .relationship($1)) } +
          entity.fetchedProperties.map { ($0, .fetched($1)) }
        )

        // Create an entity description, recursively creating entity descriptions for child nodes
        let entityDescription = NSEntityDescription()
        entityDescription.name = entity.name
        entityDescription.managedObjectClassName = NSStringFromClass(objectType)
        entityDescription.isAbstract = objectType.isAbstract
        entityDescription.renamingIdentifier = objectType.renamingIdentifier
        entityDescription.subentities = try childrenById.values.map { try $0.complete(inheritedProperties: properties) }

        // Update our state
        state = .completeEntity(entity, entityDescription, properties)

        return entityDescription
      }


    /// Return the mapping of entity names to corresponding subtrees. This method is defined only for the root node, and the returned mapping does not include the root.
    public var subtreesByName : [String: EntityTree]
      {
        switch state {
          case .completeRoot(let nodeMap), .incompleteRoot(let nodeMap) :
            return nodeMap
          default :
            preconditionFailure("invalid invocation")
        }
      }


    /// Return the associated *Entity* metadata. This method is defined only for internal nodes.
    public var entity : Entity
      {
        guard case .completeEntity(let entity, _, _) = state else { preconditionFailure("invalid invocation") }
        return entity
      }


    /// Return the associated *NSEntityDescription*. This method is defined only for internal nodes.
    public var entityDescription : NSEntityDescription
      {
        guard case .completeEntity(_, let entityDescription, _) = state else { preconditionFailure("invalid invocation") }
        return entityDescription
      }


    /// Return the mapping of property names to property metadata, closed under inheritance. This method is defined only for internal nodes.
    public var allPropertiesByName : [String: Property]
      {
        guard case .completeEntity(_, _, let propertiesByName) = state else { preconditionFailure("invalid invocation") }
        return propertiesByName
      }


    internal func withEntity(update: (inout Entity) -> Void)
      {
        guard case .incompleteEntity(var entity) = state else { preconditionFailure("invalid invocation") }
        update(&entity)
        state = .incompleteEntity(entity)
      }


    public subscript<Value> (dynamicMember path: KeyPath<Entity, Value>) -> Value
      {
        entity[keyPath: path]
      }
  }
