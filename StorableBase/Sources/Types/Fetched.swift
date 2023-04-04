/*

  Created by David Spooner

*/

import CoreData


/// The Fetched struct defines a fetched property on a class of managed object; it is analogous to CoreData's NSFetchedPropertyDescription.

public struct Fetched
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
