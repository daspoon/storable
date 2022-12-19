/*

*/


/// Used to define placeholders for enumerated types required by GameModel.
///
public protocol UndefinedEnumeration<RawValue> : RawRepresentable, Enumeration
  {
    associatedtype RawValue
  }


extension UndefinedEnumeration
  {
    public typealias RawValue = Int

    public static var allCases : [Self]
      { return [] }

    public init?(rawValue: Self.RawValue)
      { fatalError("attempt to instantiate \(Self.self) via \(#function)") }

    public var rawValue : Self.RawValue
      { fatalError("impossible") }

    public init(json: Any) throws
      { fatalError("attempt to instantiate \(Self.self) via \(#function)") }

    public var name : String
      { fatalError("impossible") }
  }
