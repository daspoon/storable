/*

  Created by David Spooner

*/

import CoreData


/// The Fetch struct defines a fetched property on a class of managed object; it is analogous to CoreData's NSFetchedPropertyDescription.

public struct Fetch
  {
    public let fetchRequest : NSFetchRequest<NSFetchRequestResult>


    /// Declare a fetched property returning objects of a specified entity.
    public init<T: ManagedObject>(
      objectsOf t: T.Type,
      predicate: NSPredicate? = nil,
      sortDescriptors: [NSSortDescriptor] = [],
      propertiesToFetch: [String]? = nil,
      includesPendingChanges: Bool = true,
      includesPropertyValues: Bool = true,
      includesSubentities: Bool = true
    ) {
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: t.entityName)
        fetchRequest.resultType = .managedObjectResultType
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.propertiesToFetch = propertiesToFetch
        fetchRequest.includesPendingChanges = includesPendingChanges
        fetchRequest.includesPropertyValues = includesPropertyValues
        fetchRequest.includesSubentities = includesSubentities
      }


    /// Declare a fetched property to count objects of a specified entity.
    public init<T: ManagedObject>(
      countOf t: T.Type,
      predicate: NSPredicate? = nil,
      includesPendingChanges: Bool = true,
      includesSubentities: Bool = true
    ) {
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: t.entityName)
        fetchRequest.resultType = .countResultType
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        fetchRequest.includesPendingChanges = includesPendingChanges
        fetchRequest.includesSubentities = includesSubentities
      }


    /// Declare a fetched property return object identifiers for a specified entity..
    public init<T: ManagedObject>(
      identifiersOf t: T.Type,
      predicate: NSPredicate? = nil,
      sortDescriptors: [NSSortDescriptor] = [],
      includesPendingChanges: Bool = true,
      includesSubentities: Bool = true
    ) {
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: t.entityName)
        fetchRequest.resultType = .managedObjectIDResultType
        fetchRequest.includesPropertyValues = false
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.includesPendingChanges = includesPendingChanges
        fetchRequest.includesSubentities = includesSubentities
      }


    /// Declare a fetched property returning objects of a specified entity.
    public init<T: ManagedObject>(
      dictionariesOf t: T.Type,
      predicate: NSPredicate? = nil,
      sortDescriptors: [NSSortDescriptor] = [],
      propertiesToFetch: [String]? = nil,
      includesPendingChanges: Bool = true,
      includesPropertyValues: Bool = true,
      includesSubentities: Bool = true
    ) {
        fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: t.entityName)
        fetchRequest.resultType = .managedObjectResultType
        fetchRequest.includesPropertyValues = true
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.propertiesToFetch = propertiesToFetch
        fetchRequest.includesPendingChanges = includesPendingChanges
        fetchRequest.includesPropertyValues = includesPropertyValues
        fetchRequest.includesSubentities = includesSubentities
      }
  }


// MARK: --

/// The Fetch macro applied to member variables of an ManagedObject subclass generates instances of the Fetch struct.
/// The macros have four forms corresponding to the four cases of NSFetchRequestResultType: the form without a leading type argument corresponds to fetched objects, with the declaration type determining the target entity;
/// the fetch type of the other three forms cis determined by the leading argument label:
///  * *countOf * corresponds to an integer count of the matching objects (of the specified entity type);
///  * *identifiersOf* corresponds an array of identifiers of the matching objects;
///  * *dictionariesOf* corresponds to an array of dictionary representations of the matching objects.
/// Note that a separate macro definition is required for each combination of optional parameter to corresponding init method of struct Fetch.

// Fetch objects
@attached(accessor)
public macro Fetch() = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch(predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch(sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch(predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetch count
@attached(accessor)
public macro Fetch<T: ManagedObject>(countOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(countOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(countOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(countOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetch identifiers
@attached(accessor)
public macro Fetch<T: ManagedObject>(identifiersOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(identifiersOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(identifiersOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(identifiersOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

// Fetch dictionaries
@attached(accessor)
public macro Fetch<T: ManagedObject>(dictionariesOf: T.Type) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(dictionariesOf: T.Type, predicate: NSPredicate) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(dictionariesOf: T.Type, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
@attached(accessor)
public macro Fetch<T: ManagedObject>(dictionariesOf: T.Type, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")
