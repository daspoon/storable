## Overview

This project explores the potential of creating CoreData object models from Swift code by applying macros to class and property declarations.
It aims to provide an alternative to Xcode's object model editor which:
  - unifies specification of object model and custom logic as Swift code;
  - enables composition of object models;
  - makes property metadata available for tasks such as data import and export;
  - simplifies support for non-standard attribute types.

This project is a work in progress and must be built with the development snapshot toolchain.
As Swift macros are an experimental feature, this system cannot be used directly to build applications for distribution on the App Store.


## Targets

The primary code is split across the following targets:
  - **StorableBase** is a framework implementing object model generation
  - **StorableMacros** is a dynamic library implementing custom macro types
  - **Storable** is a framework combining **StorableBase** and **StorableMacros**


## Types

[ManagedObject](https://github.com/daspoon/storable/blob/main/StorableBase/Types/ManagedObject.swift) is a subclass of *NSManagedObject* which serves as the abstract base class for entity definitions.

[Storable](https://github.com/daspoon/storable/blob/main/StorableBase/Types/Storable.swift) is the protocol which specifies the requirements of supported attribute types.

[ManagedPropertyMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/ManagedPropertyMacro.swift) is a protocol describing the requirements of accessor macros used to define managed object properties;
[AttributeMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/AttributeMacro.swift), [RelationshipMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/RelationshipMacro.swift), and [FetchedMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/FetchedMacro.swift) are the conforming implementations which define descriptors for attributes, relationships and fetched properties.
[Attribute](https://github.com/daspoon/storable/blob/main/StorableBase/Types/Attribute.swift), [Relationship](https://github.com/daspoon/storable/blob/main/StorableBase/Types/Relationship.swift) and [Fetched](https://github.com/daspoon/storable/blob/main/StorableBase/Types/Fetched.swift) are custom descriptor types corresponding to the three subclasses of *NSPropertyDescription*;
each is accompanied by a same-named macro declaration which identifies the corresponding macro implementation type.

[EntityMacro]() is a member macro used to aggregate the managed properties of an associated *ManagedObject* class.
The [Entity](https://github.com/daspoon/storable/blob/main/StorableBase/Types/Entity.swift) type is a custom entity descriptor corresponding to *NSEntityDescription*.

[Schema](https://github.com/daspoon/storable/blob/main/Storable/TypesBase/Schema.swift) is a structure which represents a complete object model and which generates an *NSManagedObjectModel*.

[DataStore](https://github.com/daspoon/storable/blob/main/Storable/TypesBase/DataStore.swift) is a convenience class which manages a persistent store and provides an *NSManagedObjectContext* for a given *Schema*.


## Documentation

An [introductory article](https://lambdasoftware.xyz/posts/001-storable-basics/) describes the core mechanics of the system.

A [secondary article](https://lambdasoftware.xyz/posts/002-storable-migration/) describes the impact on persistent store migration.

