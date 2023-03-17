/*

  Created by David Spooner

  This file defines the macros used to declare managed entities and properties.
  Note that macro definitions don't support optional arguments, so separate definitions are required for all combination of optional arguments.

*/

import CoreData


// MARK: - Entity -

@attached(member, names: named(declaredPropertyInfoByName))
public macro Entity() = #externalMacro(module: "StorableMacros", type: "EntityMacro")


// MARK: - Attribute -

@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute(renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute(ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute(renamingIdentifier: String, ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(defaultValue: V, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(ingestKey: IngestKey, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(defaultValue: V, ingestKey: IngestKey, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(renamingIdentifier: String, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(defaultValue: V, renamingIdentifier: String, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(renamingIdentifier: String, ingestKey: IngestKey, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute<V>(defaultValue: V, renamingIdentifier: String, ingestKey: IngestKey, transform t: @escaping (V) throws -> Any) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")


// MARK: - Relationship -

@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, ingestMode: RelationshipInfo.IngestMode) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, ingestMode: RelationshipInfo.IngestMode, ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, renamingIdentifier: String, ingestMode: RelationshipInfo.IngestMode) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, renamingIdentifier: String, ingestMode: RelationshipInfo.IngestMode, ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")


// MARK: - Fetched -

@attached(accessor)
public macro Fetched() = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

@attached(accessor)
public macro Fetched<T: Entity>(countOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(countOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(countOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(countOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

@attached(accessor)
public macro Fetched<T: Entity>(identifiersOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(identifiersOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(identifiersOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(identifiersOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

@attached(accessor)
public macro Fetched<T: Entity>(dictionariesOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(dictionariesOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(dictionariesOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: Entity>(dictionariesOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
