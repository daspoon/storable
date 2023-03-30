---
date: 2023-03-30T00:00:00-06:00
---

## Overview

This project explores the potential of creating CoreData object models from Swift code by applying macros to class and property declarations.
It aims to provide an alternative to Xcode's object model editor which:
  - unifies specification of object model and custom logic as Swift code;
  - enables composition of object models;
  - makes property metadata available for tasks such as data import and export;
  - simplifies support for non-standard attribute types.

This project is a work in progress and, as Swift macros are an experimental feature, cannot be used directly to build applications for distribution on the App Store.


## Core Types

The primary codebase is split into two targets: Storable and StorableMacros.
The latter is a dynamic library containing macro definitions as currently required by Swift's macro system.
  
[ManagedObject](https://github.com/daspoon/storable/blob/main/Storable/Types/ManagedObject.swift) is a subclass of *NSManagedObject* which serves as the abstract base class for entity definitions.

[Storable](https://github.com/daspoon/storable/blob/main/Storable/Types/Storable.swift) is the protocol which specifies the requirements of supported attribute types.

[ManagedPropertyMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/ManagedPropertyMacro.swift) is a protocol describing the requirements of accessor macros used to define managed object properties;
[AttributeMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/AttributeMacro.swift), [RelationshipMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/RelationshipMacro.swift), and [FetchedMacro](https://github.com/daspoon/storable/blob/main/StorableMacros/FetchedMacro.swift) are the conforming implementations which define descriptors for attributes, relationships and fetched properties.
[Attribute](https://github.com/daspoon/storable/blob/main/Storable/Types/Attribute.swift), [Relationship](https://github.com/daspoon/storable/blob/main/Storable/Types/Relationship.swift) and [Fetched](https://github.com/daspoon/storable/blob/main/Storable/Types/Fetched.swift) are custom descriptor types corresponding to the three subclasses of *NSPropertyDescription*;
each is accompanied by a same-named macro declaration which identifies the corresponding macro implementation type.

[EntityMacro]() is a member macro used to aggregate the managed properties of an associated *ManagedObject* class.
The [Entity](https://github.com/daspoon/storable/blob/main/Storable/Types/Entity.swift) type is a custom entity descriptor corresponding to *NSEntityDescription*.

[Schema](https://github.com/daspoon/storable/blob/main/Storable/Types/Schema.swift) is a structure which represents a complete object model and which generates an *NSManagedObjectModel*.

[DataStore](https://github.com/daspoon/storable/blob/main/Storable/Types/DataStore.swift) is a convenience class which manages a persistent store and provides an *NSManagedObjectContext* for a given *Schema*.


## Documentation

An [introductory article](posts/basics) describes the core mechanics of the system.

A [secondary article](posts/migration) describes the impact on persistent store migration.

