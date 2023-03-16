/*

  Created by David Spooner

*/

@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")

@attached(accessor)
public macro Relationship(inverse: RelationshipInfo.InverseSpec, deleteRule: RelationshipInfo.DeleteRule) = #externalMacro(module: "StorableMacros", type: "RelationshipMacro")

@attached(member, names: named(declaredPropertyInfoByName))
public macro Entity() = #externalMacro(module: "StorableMacros", type: "EntityMacro")
