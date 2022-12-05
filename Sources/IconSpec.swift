/*

*/


public struct IconSpec : Ingestible
  {
    public enum Source : String { case system, bundle }

    public let name : String
    public let source : Source
    public let color : Color

    public init(name: String, source: Source, color: Color)
      {
        self.name = name
        self.source = source
        self.color = color
      }

    public init(json dict: [String: Any]) throws
      {
        name = try dict.requiredValue(for: "name")
        source = try dict.requiredValue(for: "source")
        color = try dict.requiredValue(for: "color")
      }
  }
