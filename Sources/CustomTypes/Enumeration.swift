/*

*/


public protocol Enumeration : RawRepresentable<Int>, CaseIterable, CustomStringConvertible, Hashable
  {
    associatedtype Value

    /// The identifying string.
    var name : String { get }
    /// The name to display with associated values. The default implementation returns name.

    var shortName : String { get }

    /// A locator for the icon to display with associated values. The default implementation expects to find an image resource with the receiver's name in the application bundle.
    var iconSpec : IconSpec { get }
  }


extension Enumeration
  {
    public var description : String
      { name }

    public var shortName : String
      { name }

    public var iconSpec : IconSpec
      { .init(name: name, source: .bundle, tintColor: .label) }
  }
