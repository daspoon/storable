/*

*/


public struct Color
  {
    public var red, green, blue, alpha : Double

    public init(red r: Double, green g: Double, blue b: Double, alpha a: Double = 1)
      {
        red = r
        green = g
        blue = b
        alpha = a
      }
  }


extension Color : Ingestible
  {
    public init(json values: [Double]) throws
      {
        guard (3 ... 4).contains(values.count) else { throw Exception("expecting array of 3 or 4 component values") }
        red = values[0]
        green = values[1]
        blue = values[2]
        alpha = values.count == 4 ? values[3] : 1
      }
  }


extension Color
  {
    public var swiftText : String
      { ".init(red: \(red), green: \(green), blue: \(blue), alpha: \(alpha))" }
  }
