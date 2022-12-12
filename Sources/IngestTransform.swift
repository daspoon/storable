/*

*/


public protocol IngestTransform : CustomStringConvertible
  {
    associatedtype Input
    associatedtype Output

    func validate(_ input: Any) throws -> Input

    func transform(_ input: Input) throws -> Output
  }


extension IngestTransform
  {
    public var description : String
      { "\(Self.self)()" }
  }


public func ingestTransform(named name: String) throws -> any IngestTransform
  {
    switch name {
      case "unpack" :
        return Unpack()
      default :
        throw Exception("unknown transform '\(name)'")
    }
  }


public struct Unpack : IngestTransform
  {
    public init() {}

    public func validate(_ json: Any) throws -> String
      { try throwingCast(json) }

    public func transform(_ string: String) throws -> [String]
      { string.map { String($0) } }
  }
