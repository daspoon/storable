/*

  Created by David Spooner

*/

import CoreData


/// FetchedPropertyInfo maintains the data required to define a fetched property on a subclass of Entity; it is analogous to CoreData's NSFetchedPropertyDescription.

public struct FetchedPropertyInfo
  {
    public let fetchRequest : NSFetchRequest<NSFetchRequestResult>


    /// Declare a fetched property returning objects of a specified entity.
    public init<T: Entity>(
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
    public init<T: Entity>(
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
    public init<T: Entity>(
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
    public init<T: Entity>(
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
