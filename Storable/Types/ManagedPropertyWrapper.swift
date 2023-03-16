/*

  Created by David Spooner

*/


/// The ManagedProperty protocol is used to identify the custom property wrappers which implement managed properties on subclasses of Entity.

public protocol ManagedPropertyWrapper
  {
    /// The descriptor for the declared property.
    var propertyInfo : PropertyInfo { get }
  }