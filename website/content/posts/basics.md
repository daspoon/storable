---
title: "Swift macros for CoreData object models"
author: "David Spooner"
date: 2023-03-31T00:00:00-06:00
---

Swift macros are a feature currently in development by the Swift open source project, and CoreData is Apple's object persistence framework.
In standard usage, CoreData object models are created using Xcode's graphical model editor, Xcode generates Swift class definitions from component entity descriptions, and the NSManaged property wrapper provides Swift code with a typed interface to managed property values. While a visual overview of a data model's objects and relationships is appealing, Xcode's model editor is cumbersome for inspecting property definitions, does not promote composition of models, and forces a separation between a model definition as an XML archive and custom logic written in Swift. This article presents a system to create CoreData object models by applying Swift macros to class and property declarations.
For example:

    @Entity class Person : ManagedObject {
      @Attribute var name : String
      @Relationship(inverse: "people", deleteRule: .nullify) var place : Place?
    }

This approach natually supports composition through inheritance, provides streamlined support for attributes of Swift value types such as Codable, and enables property metadata to be leveraged for tasks such as data import and export.

We begin with a brief review of CoreData terminology and the mechanics of Swift macros as they relate to the current development.
The second section introduces the protocols used to identify the supported attribute types.
The third section describes the data structures used to represent managed object models.
The fourth section defines the macros from which our object model structures are generated.
The final section considers some essential differences between macros and property wrappers as they relate to the present system.

The presented code has minor changes and omissions made to simplify the article narrative; full source is available in the [repository](https://github.com/daspoon/storable/tree/article-1).


## Preliminaries

This section provides brief overviews of Apple's CoreData framework and Swift's proposed macro features to aid in understanding the presented system.


### CoreData

CoreData is Apple's framework for maintaining object graphs in persistent stores.
The format of a persistent store is determined by an object model, which is represented by an object of type *NSManagedObjectModel*.
An object model consists of a set of entity descriptions, each represented by an *NSEntityDescription*.
An entity description has a name, a class used to represent entity instances, and a set of property descriptions.
Property descriptions are represented by the concrete subclasses of *NSPropertyDescription*; specifically *NSAttributeDescription*, *NSRelationshipDescription* and *NSFetchedPropertyDescription*.
Instances of entities retrieved from a CoreData store are objects of type *NSManagedObject* or one of its subclasses,
and access/update of a managed object's properties is ultimately defined in terms of the underlying store.

For further information on CoreData, please refer to Apple's [documentation](https://developer.apple.com/documentation/coredata).


### Swift macros

Swift macros provide a means to improve economy of expression in various problem domains.
A [design document](https://github.com/apple/swift-evolution/blob/main/visions/macros.md) was recently accepted by Swift Evolution and an implementation is available for experimentation in the development snapshots on [Swift's download page](https://www.swift.org/download/).

Swift macros are ultimately operations on syntax structures.
Swift distinguishes between two kinds of macro: *freestanding* macros serve to generate expressions, statements and declarations; *attached* macros serve to extend an associated declaration.
Each kind of macro has various forms or *roles* which determine their context of use and scope of effect.
Each role corresponds to a protocol in the *SwiftSyntaxMacros* module which specifies the signature of its expansion method.
The current article is concerned only with attached macros; in particular the *accessor* role which enables adding accessor methods to property declarations, and the *member* role which enables adding methods to class declarations.

Implementing a custom macro in Swift requires two steps.
The first is to define an attribute which determines the kind and role of the macro, along with its associated implementation type.

    @attached(accessor)
    public macro MyMacro() = #externalMacro(module: "MyDylib", type: "MyMacro")

The #*externalMacro* syntax specifies the name of the implementation type and the dynamic library in which it resides;
it allows the Swift compiler to safely execute arbitrary expansion code and is currently the only means of providing a macro implementation.
Macro attribute definitions specify a signature for arguments passed to the implementation type, and signatures may be both overloaded and generic.
Unfortunately default arguments are not (currently) supported, so implementations involving multiple optional arguments must provide a separate definitions for each possible sequence of arguments.

The second step is to define a type which implements the protocol for the desired role.
Each protocol specifies an expansion method which takes as arguments the applied attribute, the affected declaration, and a context providing name generation and diagnostic features.
The protocols differ primarily in the types of the affected and resulting declarations.
For example, the *AccessorMacro* protocol corresponding to the *accessor* role which maps an arbitrary declaration to a list of accessor declarations.

    static func expansion<Context, Declaration>(
        of attribute: AttributeSyntax, 
        providingAccessorsOf declaration: Declaration, 
        in context: Context
      ) throws -> [AccessorDeclSyntax]
      where Context: MacroExpansionContext, Declaration: DeclSyntaxProtocol

The *MemberMacro* protocol corresponds to the *member* role which maps a composite declaration, such as a class or structure, to a list of arbitrary component declarations.

    static func expansion(
        of attribute: AttributeSyntax, 
        providingMembersOf declaration: some DeclGroupSyntax, 
        in context: some MacroExpansionContext
      ) throws -> [DeclSyntax]

In either case the expansion method may throw to indicate that expansion is not valid in the given scenario, and the resulting declarations may be expressed as a list of (interpolated) string literals.

    return [ "..." ]

Implementing expansion methods requires some study of the *SwiftSyntax* APIs to understand how to validate expansion with respect to the associated declaration, how to extract information such as variable names and types from declarations, and how to extract arguments from attributes; the [example macros project](https://github.com/DougGregor/swift-macro-examples) is very helpful for this purpose.


## Storable attribute types

This section presents the custom protocols used to identify supported attribute types and thus to restrict application of subsequently-defined macros.


### Standard types

The [StorageType](https://github.com/daspoon/storable/blob/article-1/Storable/Types/StorageType.swift) protocol identifies the attribute types, such as *Int* and *String*, supported directly by CoreData.

    protocol StorageType {
      static var typeId : NSAttributeDescription.StorageType { get }
    }

Conformance for those types is defined explicitly.

    extension Bool : StorageType {
      static var typeId : NSAttributeDescription.StorageType
        { .boolean }
    }
    ...

The [Storable](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Storable.swift) protocol enables a wider range of attribute types; it identifies types which have a translation to and from an associated StorageType.

    protocol Storable {
      associatedtype EncodingType : StorageType
      func storedValue() -> EncodingType
      static func decodeStoredValue(_ storedValue: EncodingType) -> Self
      static var valueTransformerName : NSValueTransformerName? { get }
    }

An implementation of the static *valueTransformerName* property is required only if the *typeId* of the associated *EncodingType* is *transformable*.

    extension Storable {
      static var valueTransformerName : NSValueTransformerName?
        { precondition(EncodingType.typeId != .transformable); return nil }
    }

All types conforming to *StorageType* are *Storable* through the following extension, 

    extension StorageType {
      func storedValue() -> Self
        { self }
      static func decodeStoredValue(_ value: Self) -> Self
        { value }
    }

although conformance must be declared explicitly on each concrete type.

    extension Bool : Storable {}
    ...


### Non-standard types

Attributes of types conforming to *RawRepresentable* and *Codable* protocols are supported through extensions on those protocols.
A *RawRepresentable* is *Storable* when its *RawValue* is a *StorageType*,

    extension RawRepresentable where RawValue : StorageType {
      func storedValue() -> RawValue
        { rawValue }
      static func decodeStoredValue(_ storedValue: RawValue) -> Self {
        guard let value = Self(rawValue: storedValue)
          else { fatalError("'\(storedValue)' is not an acceptible raw value of \(Self.self)") }
        return value
      }
    }

but conformance must be declared explicitly on concrete types; for example:

    enum MyCustomEnum : Int, Storable
      { case low, medium, high }

Any *Codable* type could be made *Storable* by defining the required methods to explicitly translate to and from *Data*, but this begs the question of how to cache translation results;
CoreData's *transformable* attributes provide a convenient solution.
Start with a generic class [Boxed](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Boxed.swift) for boxing *Codable* types as objects,

    class Boxed<Value: Codable> : NSObject, NSSecureCoding {
      let value : Value
      init(value v: Value)
        { value = v }
      ...
    }

along with a corresponding subclass [BoxedValueTransformer](https://github.com/daspoon/storable/blob/article-1/Storable/Types/BoxedValueTransformer.swift) of *ValueTransformer*.

    final class BoxedValueTransformer<Value: Codable> : ValueTransformer {
      override class func transformedValueClass() -> AnyClass
        { Boxed<Value>.self }
      override class func allowsReverseTransformation() -> Bool
        { true }
      override func transformedValue(_ any: Any?) -> Any?
        { ... }
      override func reverseTransformedValue(_ any: Any?) -> Any?
        { ... }
    }

The *NSAttributeDescription* for a *transformable* attribute requires the name of a *ValueTransformer* instance,
which means each *Codable* attribute type *T* must determine a unique name for an instance of *BoxedValueTransformer\<T\>* registered prior to opening the associated store.
This is done through an extension on *NSValueTransformerName* which maps *Codable* types to registered instances names, and which registers new instances where necessary.

    static func boxedValueTransformerName<T>(for type: T.Type) -> NSValueTransformerName
      where T : Codable
      { ... }

Finally, to avoid ambiguity for types conforming to both *StorageType* and *Codable*, we implement *Storable* conformance for *Codable* types through an auxiliary protocol [StorableAsData](https://github.com/daspoon/storable/blob/article-1/Storable/Types/StorableAsData.swift).

    protocol StorableAsData : Storable where Self : Codable, EncodingType == Boxed<Self>
      { }

    extension StorableAsData {
      func storedValue() -> Boxed<Self>
        { Boxed(value: self) }
      static func decodeStoredValue(_ boxed: Boxed<Self>) -> Self
        { boxed.value }
      static var valueTransformerName : NSValueTransformerName?
        { .boxedValueTransformerName(for: Self.self) }
    }

So a *Codable* type *T* is made available for use as an attribute by declaring conformance to *StorableAsData*, which we do as a convenience for *Array* and *Dictionary* types.

    extension Array : Storable, StorableAsData
      where Element : Codable {}
      
    extension Dictionary : Storable, StorableAsData
      where Key : Codable, Value : Codable {}

Note that the effect of *StorableAsData* is that attribute values of *Codable* type *T* are passed to and from CoreData's persistence layer as instances of *Boxed\<T\>*.


### Optional types

While it is possible to extend the *Storable* protocol to cover optional types, doing so complicates the implementation of macro expansion and of features beyond the scope of this article.
Instead we identify optional types through a protocol which defines a translation to and from *Optional*,

    protocol Nullable : ExpressibleByNilLiteral {
      associatedtype Wrapped
      static func inject(_ value: Wrapped) -> Self
      static func project(_ nullable: Self) -> Wrapped?
    }

and define conformance for *Optional* as an extension.

    extension Optional : Nullable {
      static func inject(_ value: Wrapped) -> Self
        { Self(value) }
      static func project(_ valueOrNil: Self) -> Wrapped?
        { valueOrNil }
    }

In effect, the type of an optional attribute is a *Nullable* type whose *Wrapped* type conforms to *Storable*.


## Object model descriptors

This section describes the custom data structures used to represent object model components, and how these components are combined to form an *NSManagedObjectModel*.
The component types are roughly equivalent to their CoreData counterparts, but are generally value types and maintain additional information.


### Classes

We begin with a custom class [ManagedObject](https://github.com/daspoon/storable/blob/article-1/Storable/Types/ManagedObject.swift) of *NSManagedObject* in order to impose some additional structure on the subclasses which describe entities:
most importantly, a mapping of managed property names to descriptor instances.

    open class ManagedObject : NSManagedObject {
      class var entityName : String
        { "\(Self.self)" }
      open class var declaredPropertiesByName : [String: Property]
        { [:] }
    }

The *Property* type, which unifies the three kinds of managed property, is defined later in this section.


### Properties

The [Attribute](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Attribute.swift) type corresponds to CoreData's *NSAttributeDescription*.

    struct Attribute {
      let name : String
      let type : Any.Type
      let attributeType : NSAttributeDescription.AttributeType
      let valueTransformerName : NSValueTransformerName?
      let defaultValue : (any Storable)?
      let isOptional : Bool
    }

Although not generic, *Attribute* has initializers with generic constraints limiting application to types which are either *Storable*

    init<T: Storable>(name: String, type t: T.Type, defaultValue v: T? = nil)
      { self.init(name: name, type: t, isOptional: false, defaultValue: v) }

or *Nullable* with associated *Wrapped* type *Storable*.

    init<T: Nullable>(name: String, type t: T.Type, defaultValue v: T.Wrapped? = nil)
      where T.Wrapped : Storable
      { self.init(name: name, type: T.Wrapped.self, isOptional: true, defaultValue: v) }

The [Relationship](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Relationship.swift) type corresponds to *NSRelationshipDescription*.

    struct Relationship {
      let name : String
      let range : ClosedRange<Int>
      let relatedEntityName : String
      let inverse : InverseSpec
      let deleteRule : DeleteRule
    }

The member type *InverseSpec* specifies an inverse relationship in the destination entity either implicitly as a name or explicitly by providing all necessary details.

    struct InverseSpec : ExpressibleByStringLiteral {
      var name : String
      var detail : (range: ClosedRange<Int>, deleteRule: DeleteRule)?
    }

The member type *DeleteRule* simply provides more concise case names for its *NSDeleteRule* counterpart.

    enum DeleteRule
      { case noAction, nullify, cascade, deny }

The initializers of *Relationship* have generic constraints limiting application to property types consistent with to-one, to-optional and to-many relationships.

    init<T: ManagedObject>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule)
      { self.init(name: name, range: 1 ... 1, relatedEntityName: T.entityName, inverse: inv, deleteRule: r) }

    init<T: Nullable>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule) where T.Wrapped : ManagedObject
      { self.init(name: name, range: 0 ... 1, relatedEntityName: T.Wrapped.entityName, inverse: inv, deleteRule: r) }

    init<T: SetAlgebra>(name: String, type: T.Type, inverse inv: Relationship.InverseSpec, deleteRule r: Relationship.DeleteRule) where T.Element : ManagedObject
      { self.init(name: name, range: 0 ... .max, relatedEntityName: T.Element.entityName, inverse: inv, deleteRule: r) }

The [Fetched](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Fetched.swift) type corresponds to *NSFetchedPropertyDescription* and maintains an *NSFetchRequest* instance.

    struct Fetched {
      let fetchRequest : NSFetchRequest<NSFetchRequestResult>
    }

The target entity type is a required initialization parameter, and is used along with optional parameters to configure the associated fetch request.
Four initializers are provided according to the four possible fetch result types, and differ primarily in the name of the first argument.

    init<T: ManagedObject>(objectsOf t: T.Type, ...)
    init<T: ManagedObject>(countOf t: T.Type, ...)
    init<T: ManagedObject>(identifiersOf t: T.Type, ...)
    init<T: ManagedObject>(dictionariesOf t: T.Type, ...)

Finally, the [Property](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Property.swift) type unifies the three descriptor types to enable forming collections.

    enum Property {
      case attribute(Attribute)
      case relationship(Relationship)
      case fetched(Fetched)
    }


### Entities

The [Entity](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Entity.swift) type corresponds to an *NSEntityDescription*.
Unsurprisingly it maintains an entity name, a managed object class, and mappings of names to property descriptors by type.

    struct Entity {
      let name : String
      let managedObjectClass : ManagedObject.Type
      let attributes : [String: Attribute]
      let relationships : [String: Relationship]
      let fetchedProperties : [String: Fetched]
    }

An instance of *Entity* is initialized with a *ManagedObject* subclass, and populates its property descriptor maps according to the *declaredPropertiesByName* method of the given class.

    init(objectType: ManagedObject.Type) throws
      { ... }


### Schemas

The [Schema](https://github.com/daspoon/storable/blob/article-1/Storable/Types/Schema.swift) type represents a managed object model involving a given set of *ManagedObject* subclasses closed under inheritance;
it generates an *NSManagedObjectModel* on demand.

    struct Schema {
      init(objectTypes: [ManagedObject.Type]) throws
        { ... }
      func createManagedObjectModel() throws -> NSManagedObjectModel
        { ... }
    }

The details are not relevant to the presented macros and are omitted.


## Macros for object managed models

This section presents the macros used to construct object model components.
We begin with macros to define the three kinds of managed properties, and folow-up with a macro to define entities.


### Properties

Property declaration macros have two purposes: the first is to generate *get* and *set* accessors which function in terms of the key-value coding methods of an enclosing object; the second is to generate expressions representing property descriptor instances.
The first purpose is served by deriving from *AccessorMacro* and the second involves combining descriptor arguments provided explicitly to macro application with those inferred from the associated declaration.
We begin with the [ManagedPropertyMacro](https://github.com/daspoon/storable/blob/article-1/StorableMacros/ManagedPropertyMacro.swift) protocol which states the requirements of a managed property macro beyond being an *AccessorMacro*.

    protocol ManagedPropertyMacro : AccessorMacro {
      static func inferredMetadataConstructorArguments(
        for info: StoredPropertyInfo, 
        with attr: AttributeSyntax
      ) -> String?
    }

The required method determines the initial sequence of arguments to the generated property descriptor which are inferred from the affected declaration.
The *StoredPropertyInfo* type aggregates the relevant data of the property declaration, specifically its name, type and optional initial value.

    typealias StoredPropertyInfo = (name: String, type: TypeSyntax, value: ExprSyntax?)

An extension provides additional methods to simplify interaction with conforming types.
The first determines the type of the generated descriptor, and returns the macro type name sans the "Macro" suffix.

    static var attributeName : String

The second extracts *StoredPropertyInfo* from a declaration, ensuring that declaration represents a stored property -- which, for our purpose, binds a single variable name and has no explicit accessors other than *willSet* and *didSet*.

    static func getStoredPropertyInfo(from decl: DeclSyntaxProtocol)
      throws -> StoredPropertyInfo

The third generates an expression representing a new property descriptor instance by combining inferred and explicit arguments.

    static func metadataConstructorExpr(
      for info: StoredPropertyInfo, 
      with attr: AttributeSyntax
    ) -> ExprSyntax

The macro implementation types are located in the StorableMacros target.
The expansion method required by *AccessorMacro* is implemented explicitly for each property macro type,
and each implementation begins by ensuring the associated declaration represents a stored property and throwing an error otherwise.
The definitions of the corresponding macro attributes are located along with the associated descriptor type in the Storable target.

With the general structure laid out, we now describe the macro types for each kind of managed property.


### Attributes

The [AttributeMacro](https://github.com/daspoon/storable/blob/article-1/StorableMacros/AttributeMacro.swift) type defines a managed attribute and is applicable to stored property declarations of any *Storable* type.
The descriptor arguments inferred from the associated declaration are the property name, type and optional default value.

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> String?
      { "name: \"\(info.name)\", type: \(info.type.longName).self" + (info.value.map {", defaultValue: \($0)"} ?? "") }

Note that the *type* argument to the generated descriptor determines the generic overload of *Attribute.init*,
and that *longName* is a custom extension of Swift's *TypeSyntax* which ensures optional types are written as *Optional\<T\>* rather than *T?*.

The effect of the expansion method depends on whether or not the declaration type is optional.

    static func expansion<Ctx, Dcl>(of node: AttributeSyntax, providingAccessorsOf dcl: Dcl, in ctx: Ctx) 
      throws -> [AccessorDeclSyntax]
      where Ctx: MacroExpansionContext, Dcl: DeclSyntaxProtocol 
      {
        let info = try getStoredPropertyInfo(from: dcl)
        switch info.type.as(OptionalTypeSyntax.self) {
          case .none :
            return [ ... ]
          case .some(let optionalType) :
            return [ ... ]
        }
      }

The interpolated string literals for each generated accessor method are present separately below, omitting enclosing triple-quotes and beginning with the getter for non-optional types.
Note that property values retrieved by *value(forKey:)* have type *Any?*: if the value of a non-optional attribute is nil then that attribute must be uninitialized, which is an error;
otherwise, barring subversion of the type system via *setValue(:forKey:)*, the type of the retrieved value must be the *EncodingType* of the *Storable* declaration type and so we return its decoding.

    get {
      switch self.value(forKey: "\(raw: info.name)") {
        case .some(let objectValue) :
          guard let encodedValue = objectValue as? \(raw: info.type).EncodingType
            else { fatalError("\(raw: info.name) is not of expected type") }
          return \(raw: info.type).decodeStoredValue(encodedValue)
        case .none :
          fatalError("\(raw: info.name) is not initialized")
      }
    }
    
The setter for non-optional types needs only to invoke *setValue(:forKey:)* with the encoding of the given *Storable* value.

    set {
      self.setValue(newValue.storedValue(), forKey: "\(raw: info.name)")
    }

Within the getter of an optional type, a retrieved value of *nil* is acceptable.
If a retrieved value is non-*nil* then it must be of the *EncodingType* of the optional's wrapped type, and the decoding of that value is made optional by the declared type's *inject* method.

    get {
      switch self.value(forKey: "\(raw: info.name)") {
        case .some(let objectValue) :
          guard let encodedValue = objectValue as? \(raw: optionalType.wrappedType).EncodingType
            else { fatalError("\(raw: info.name) is not of expected type ...") }
          return \(raw: optionalType.longName).inject(\(raw: optionalType.wrappedType).decodeStoredValue(encodedValue))
        case .none :
          return nil
      }
    }

The setter for an optional type projects the wrapped value of the given *Nullable* value and stores its encoding (or *nil* if the projected value is *nil*).

    set {
      self.setValue(\(raw: optionalType.longName).project(newValue)?.storedValue(), forKey: "\(raw: info.name)")
    }

Finally we require only a single macro attribute definition.
Note that generic constraints cannot be used to restrict application since property type and default value are implicit in the declaration; we must rely on type checking of the macro-expanded code to flag inappropriate application.

    @attached(accessor)
    macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")


### Relationships

The [RelationshipMacro](https://github.com/daspoon/storable/blob/article-1/StorableMacros/RelationshipMacro.swift) type defines a managed relationship and is applicable to stored property declarations of types *T*, *T?*, or *Set<T>* for any managed object subclass *T*.

The descriptor arguments inferred from the associated declaration are the property name and type.

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attr: AttributeSyntax) -> String?
      { "name: \"\(info.name)\", type: \(info.type.longName).self" }

The *get* accessor retrieves the stored value from CoreData, ensuring it is of the property declaration type.
Barring subversion of the type system, casting the retrieved value will fail only for uninitialized to-one relationships since empty to-many relationships are retrieved by CoreData as empty sets.

    get {
      let storedValue = self.value(forKey: "\(raw: info.name)")
      guard let value = storedValue as? \(raw: info.type)
        else { fatalError("\(raw: info.name) is not of expected type") }
      return value
    }
    
The *set* accessor simply stores the given value.

    set {
      setValue(newValue, forKey: "\(raw: info.name)")
    }

The single macro attribute definition requires arguments specifying the inverse relationship and delete rule.

    @attached(accessor)
    public macro Relationship(inverse: Relationship.InverseSpec, deleteRule: Relationship.DeleteRule)
      = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")

Again we must rely on type checking of the macro-expaned code to detect inappropriate application as there is no reliable way for the macro implementation to ensure the declaration type meets the generic constraints set out by *Relationship*.


### Fetched properties

The [FetchedMacro](https://github.com/daspoon/storable/blob/article-1/StorableMacros/FetchedMacro.swift) type is more complicated.
We add a corresponding enum corresponding to the four types of fetched results.

    enum Mode { case objects, count, identifiers, dictionaries }

Recall that the four initializers of the *Fetched* descriptor type require a *ManagedObject* type as the first argument, and that each initializer has a distinct label for that argument.
For property declarations representing fetched objects, the type parameter is inferred from the declartion and need not be provided to the macro application.

    @attached(accessor)
    macro Fetched(...) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

The other three forms, however, require a leading type argument with label matching that of the corresponding descriptor initializer.

    @attached(accessor)
    macro Fetched<T: ManagedObject>(countOf: T.Type, ...) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

    @attached(accessor)
    macro Fetched<T: ManagedObject>(identifiersOf: T.Type, ...) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

    @attached(accessor)
    macro Fetched<T: ManagedObject>(dictionariesOf: T.Type, ...) = #externalMacro(module: "StorableMacros", type: "FetchedMacro")

Thus the Mode for a macro attribute is determined by its first argument,

    static func mode(for attribute: AttributeSyntax) -> Mode
      { ... }

and the inferred descriptor arguments depend on that mode.

    static func inferredMetadataConstructorArguments(for info: StoredPropertyInfo, with attribute: AttributeSyntax) -> String? {
      switch mode(for: attribute) {
        case .objects :
          return "objectsOf: \(info.type.arrayElementType!).self"
        default :
          return nil
      }
    }

The expansion method imposes approximate constraints on the declaration type according to the form of the applied attribute.

    let mode = Self.mode(for: attribute)
    switch mode {
      case .objects :
        guard info.type.isCompatible(with: TypeSyntax("[Any]"))
          else { throw CustomError("@\(Self.self) is not applicable to \(info.type)") }
      case .count :
        guard info.type.isCompatible(with: TypeSyntax("Int"))
          else { throw CustomError("@\(Self.self)(countOf:) is not applicable to \(info.type)") }
      case .identifiers :
        guard info.type.isCompatible(with: TypeSyntax("[NSManagedObjectID]"))
          else { throw Exception("@\(Self.self)(identifiersOf:) is not applicable to \(info.type)") }
      case .dictionaries :
        guard info.type.isCompatible(with: TypeSyntax("[[String: Any]]"))
          else { throw Exception("@\(Self.self)(dictionariesOf:) is not applicable to type \(info.type)") }
    }

The get accessor requires a distinct definition for the *count* form of request since that returns an array of integers,

    get {
      guard let array = self.value(forKey: "\(raw: info.name)") as? [\(raw: info.type)], array.count == 1
        else { fatalError("\(raw: info.name) is not of expected format") }
      return array[0]
    }

while the other forms share the same definition.

    get {
      guard let value = self.value(forKey: "\(raw: info.name)") as? \(raw: info.type)
        else { fatalError("\(raw: info.name) is not of expected format") }
      return value
    }

No set accessor is generated since fetched properties are immutable.


### Entities

The [EntityMacro](https://github.com/daspoon/storable/blob/article-1/StorableMacros/EntityMacro.swift) type serves to extend a subclass of *ManagedObject* with an override of its *declaredPropertiesByName* method, and so must conform to *MemberMacro*.

    struct EntityMacro : MemberMacro
      { ... }

Generating the method override requires identifying class members which correspond to stored properties attributed by one of the managed property macros defined previously.
For this purpose we maintain the set of macro names and a mapping of names to macro types.

    static let propertyMacroTypes : [ManagedPropertyMacro.Type]
      = [AttributeMacro.self, FetchedMacro.self, RelationshipMacro.self]

    static let propertyMacroNames : Set<String>
      = Set(propertyMacroTypes.map {$0.attributeName})
      
    static let propertyMacroTypesByName : [String: ManagedPropertyMacro.Type]
      = Dictionary(uniqueKeysWithValues: propertyMacroTypes.map {($0.attributeName, $0)})

The expansion method operates on a *DeclGroupSyntax*, which is a declaration having associated member declarations.
Ideally we could restrict application to subclasses of *ManagedObject*, but the best we can do is ensure the affected declaration represents a class.

    public static func expansion(
        of attr: AttributeSyntax, 
        providingMembersOf dcl: some DeclGroupSyntax, 
        in context: some MacroExpansionContext
      ) throws -> [DeclSyntax]
      {
        guard let dcl = dcl.as(ClassDeclSyntax.self) else {
          throw Exception("@Entity is applicable only to class definitions")
        }
        ...
      }

The text for the declaration of *declaredPropertiesByName* is obtained by iterating over the class member declarations which represent stored properties with a managed property attribute,
determining the corresponding macro type, and invoking its method to generate the text for a descriptor instance; it is somewhat complicated by Swift's syntax for dictionary literals.

    var text = "public override class var declaredPropertiesByName : [String: Property] {\n"
    text.append("  return [")
    var count = 0
    for member in dcl.members.members {
      guard let vdecl = member.decl.as(VariableDeclSyntax.self) else { continue }
      guard let info = vdecl.storedPropertyInfo else { continue }
      let macroAttrs = vdecl.attributes?.attributesWithNames(propertyMacroNames) ?? []
      guard macroAttrs.count > 0 else { continue }
      guard macroAttrs.count == 1
        else { throw Exception("cannot intermix attributes among \(propertyMacroNames)") }
      let macroType = propertyMacroTypesByName[macroAttrs[0].trimmedName]!
      text.append("    \"\(info.name)\" : \(macroType.metadataConstructorExpr(for: info, with: macroAttrs[0])),\n")
      count += 1
    }
    text.append((count == 0 ? ":]" : "  ]") + "\n")
    text.append("}\n")

Finally, transforming an arbitrary string to a declaration requires an explicit constructor application.

    return [DeclSyntax(stringLiteral: text)]


## Summary

We have presented a system to generate CoreData object models from Swift source using the recently introduced macros feature, and how doing so enables streamlined support for non-standard attribute types such as Codable.
The obvious drawback is that macros are an experimental feature which may undergo changes before release and can't be used in applications distributed through the App Store.

The system was originally intended to use property wrappers as the means to specify managed properties.
That approach suffered from the fact that accessors can't know the names of properties whose types are not representable in Objective-C,
and so forces association of a descriptor instance to each managed property of each managed object instance.
The problem might have been mitigated by implementing property wrappers as classes, but for the fact that it's not currently possible for [an init method of a class to return a shared object](https://forums.swift.org/t/allow-self-x-in-class-convenience-initializers/15924/28).

Fortunately, Swift macros have provided a reasonably seamless replacement with significant benefits,
the most important being that no descriptor is necessary within accessor methods because the property names are taken directly from declarations.
The second benefit is eliminating the need for reflection in determining the managed properties of a class, using instead the custom *Entity* macro.

However, an important feature of property wrappers which is not supported by macros is the ability to precisely identify applicable types through generic overloading of init methods.
While macros can reason about the syntax of a type, it cannot determine subtype or protocol conformance or even type identity.
This means application of a macro to an unsupported type generally results in an error type checking the macro expansion, which is not a great user experience.
This missing ability is unlikely to emerge under the constraint that macro types be defined in independent dynamic libraries, although one can hope that constraint is lifted by the time macros become available in Xcode.
