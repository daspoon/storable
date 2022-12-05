/*

*/


public protocol Ingestible
  {
    associatedtype Input

    init(json: Input) throws
  }


extension RawRepresentable
  {
    public init(json v: RawValue) throws
      {
        guard let value = Self(rawValue: v) else { throw Exception("invalid value of \(Self.self): '\(v)'") }
        self = value
      }
  }


extension Array : Ingestible where Element : Ingestible
  {
    public init(json: [Element.Input]) throws
      {
        self = try json.map { try Element(json: $0) }
      }
  }


extension Dictionary : Ingestible where Key == String, Value : Ingestible
  {
    public init(json: [String: Value.Input]) throws
      {
        self = Dictionary(uniqueKeysWithValues: try json.map { ($0, try Value(json: $1)) })
      }
  }
