/*

  Created by David Spooner

*/

import CoreData


// Entity
@attached(member, names: named(declaredPropertyInfoByName))
public macro Entity() = #externalMacro(module: "StorableMacros", type: "EntityMacro")


// Attribute
@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")
@attached(accessor)
public macro Attribute(renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "AttributeMacro")


// Relationship
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")
@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule, renamingIdentifier: String) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")


// Fetched
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
