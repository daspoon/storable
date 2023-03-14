/*

  Created by David Spooner

*/

@attached(accessor)
public macro Attribute() = #externalMacro(module: "StorableMacros", type: "AttributeMacro")

@attached(member, names: named(declaredPropertyInfoByName))
public macro Entity() = #externalMacro(module: "StorableMacros", type: "EntityMacro")
