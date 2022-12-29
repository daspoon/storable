/*

*/


public struct IconSpec
  {
    public enum Source : String { case system, bundle }

    public struct Color
      {
        public var red, green, blue, alpha : Double
        public init(red r: Double, green g: Double, blue b: Double, alpha a: Double = 1)
          { red = r; green = g; blue = b; alpha = a }
      }

    public let name : String
    public let source : Source
    public let color : Color?

    public init(name: String, source: Source? = nil, color: Color? = nil)
      {
        self.name = name
        self.source = source ?? .bundle
        self.color = color
      }
  }
