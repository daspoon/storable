# Storable

This package provides a means to generate CoreData object models from Swift class definitions using property wrappers to declare managed properties. The property wrappers enable convenient support for attributes of Swift value types such as Codable and RawRepresentable.


Primary types:
  - Entity is a subclass of NSManagedObject which serves as the abstract base class for entity definitions
  - Schema is a structure which references a set of Entity subclasses and which derives an NSManagedObjectModel
  - DataStore is a convenience class for managing a persistent store and providing a managed object context for a given Schema
  - Attribute, OptionalAttribute, Relationship and FetchedProperty are property wrapper types used to declare managed properties on Entity subclasses
  - Storable is the protocol specifying the requirements of attribute types

