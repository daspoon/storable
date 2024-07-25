## Overview

This project explores the potential of creating CoreData object models from Swift code by applying macros to class and property declarations.
It aims to provide an alternative to Xcode's object model editor which:
  - unifies specification of object model and custom logic as Swift code;
  - enables composition of object models;
  - makes property metadata available for tasks such as data import and export;
  - simplifies support for non-standard attribute types.

NOTE: This project was implemented prior to the announcement of SwiftData at WWDC23 and has been made redundant by that technology; I'm not claiming originality here, as the idea is rather obvious.


## Targets

The code is split across the following targets:
  - **StorableMacros** is the library which implements the custom macros
  - **Storable** is the library which defines the core types and exports the custom macros
  - **StorableTests** is the test suite; it provides simple usage examples


## Types

[ManagedObject](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/ManagedObject.swift) is a subclass of *NSManagedObject* which serves as the abstract base class for entity definitions.

[Storable](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Storable.swift) is the protocol which specifies the requirements of supported attribute types.

[ManagedPropertyMacro](https://github.com/daspoon/storable/blob/main/Sources/StorableMacros/Types/ManagedPropertyMacro.swift) is a protocol describing the requirements of accessor macros used to define managed object properties;
[AttributeMacro](https://github.com/daspoon/storable/blob/main/Sources/StorableMacros/Macros/AttributeMacro.swift), [RelationshipMacro](https://github.com/daspoon/storable/blob/main/Sources/StorableMacros/Macros/RelationshipMacro.swift), and [FetchedMacro](https://github.com/daspoon/storable/blob/main/Sources/StorableMacros/Macros/FetchedMacro.swift) are the conforming implementations which define descriptors for attributes, relationships and fetched properties.
[Attribute](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Attribute.swift), [Relationship](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Relationship.swift) and [Fetched](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Fetched.swift) are custom descriptor types corresponding to the three subclasses of *NSPropertyDescription*;
each is accompanied by a same-named macro declaration which identifies the corresponding macro implementation type.

[EntityMacro](https://github.com/daspoon/storable/blob/main/Sources/StorableMacros/Macros/EntityMacro.swift) is a member macro used to aggregate the managed properties of an associated *ManagedObject* class.
The [Entity](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Entity.swift) type is a custom entity descriptor corresponding to *NSEntityDescription*.

[Schema](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/Schema.swift) is a structure which represents a complete object model and which generates an *NSManagedObjectModel*.

[DataStore](https://github.com/daspoon/storable/blob/main/Sources/Storable/Types/DataStore.swift) is a convenience class which manages a persistent store and provides an *NSManagedObjectContext* for a given *Schema*.


## Documentation

An [introductory article](https://lambdasoftware.xyz/posts/001-storable-basics/) describes the core mechanics of the system.

A [secondary article](https://lambdasoftware.xyz/posts/002-storable-migration/) describes the impact on persistent store migration.

