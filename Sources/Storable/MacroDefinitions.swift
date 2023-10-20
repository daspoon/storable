/*

*/

#if swift(>=5.9)

import CoreData


// MARK: --

/// The ManagedObject macro, when applied to definitions of ManagedObject subclasses, generates instances of the ManagedObject struct.

@attached(member, names: named(declaredPropertiesByName), named(propertyName(for:)))
public macro ManagedObject() = #externalMacro(module: "StorableMacros", type: "EntityMacro")


// MARK: --

/// The Attribute macro applied to member variables of a managed object subclass generates instances of the Attribute struct.
/// Note that a separate macro definition is required for each combination of optional parameter to corresponding init method of struct Attribute.

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


// MARK: --

/// The Relationship macro, when applied to member variables of an ManagedObject subclass, generates instances of the Relationship struct.
/// Note that a separate macro definition is required for each combination of optional parameter to corresponding init method of struct Relationship.

@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule, renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule, ingestMode: Relationship.IngestMode) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule, ingestMode: Relationship.IngestMode, ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule, renamingIdentifier: String, ingestMode: Relationship.IngestMode) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule, renamingIdentifier: String, ingestMode: Relationship.IngestMode, ingestKey: IngestKey) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")


// MARK: --

/// The Fetch macro applied to member variables of an ManagedObject subclass generates instances of the Fetch struct.
/// The macros have four forms corresponding to the four cases of NSFetchRequestResultType: the form without a leading type argument corresponds to fetched objects, with the declaration type determining the target entity;
/// the fetch type of the other three forms cis determined by the leading argument label:
///  * *countOf * corresponds to an integer count of the matching objects (of the specified entity type);
///  * *identifiersOf* corresponds an array of identifiers of the matching objects;
///  * *dictionariesOf* corresponds to an array of dictionary representations of the matching objects.
/// Note that a separate macro definition is required for each combination of optional parameter to corresponding init method of struct Fetch.

// Fetched objects
@attached(accessor)
public macro Fetched() = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetched count
@attached(accessor)
public macro Fetched<T: ManagedObject>(countOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(countOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(countOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(countOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetched identifiers
@attached(accessor)
public macro Fetched<T: ManagedObject>(identifiersOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(identifiersOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(identifiersOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(identifiersOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetched dictionaries
@attached(accessor)
public macro Fetched<T: ManagedObject>(dictionariesOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(dictionariesOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(dictionariesOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetched<T: ManagedObject>(dictionariesOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

#endif
