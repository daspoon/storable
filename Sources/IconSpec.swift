/*

*/


public struct IconSpec : Ingestible
  {
    public enum Source : String, Ingestible { case system, bundle }

    public let name : String
    public let source : Source
    public let color : Color?

    public init(name: String, source: Source? = nil, color: Color? = nil)
      {
        self.name = name
        self.source = source ?? .bundle
        self.color = color
      }

    public init(json dict: [String: Any]) throws
      {
        name = try dict.requiredValue(for: "name")
        source = try dict.optionalValue(for: "source") ?? .bundle
        color = try dict.optionalValue(for: "color")
      }

    public var swiftText : String
      { "IconSpec(name: \"\(name)\", source: .\(source)" + (color.map {", color: \($0.swiftText)"} ?? "") + ")" }
  }
