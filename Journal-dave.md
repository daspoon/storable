### Tue Apr 4, 2023

Make StorableBase a package 
  - including class generation tool...


### Mon Apr 3, 2023

Restructure project, adding StorableBase to enable use of core functionality independent of macros.
  - refactor macro expansion of attribute accessors to enable explicit use

Investigate use of Sourcery (https://github.com/krzysztofzablocki/Sourcery) as an alternative to macros...
  - intend to generate an extension for each affected class which overrides declaredPropertiesByName and implements accessors for annotated properties
  - unfortunately it's not possible to declare a property without providing an implementation
  - which means we can't use annotated property declarations as a hook for generating accessors
  - which means our syntax for generating class declarations may as well be JSON, which would be must simpler to implement

 Add command-line tool to generate ManagedObject class declarations from JSON descriptors.


### Sat Apr 1, 2023

Add conditional compilation of macro-dependent syntax
  - StorableMacros dylib
  - macro definitions
  - tests involving macro attributes


