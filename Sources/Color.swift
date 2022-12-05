/*

*/


public enum Color
  {
    case named(String)
    case rgba(Float, Float, Float, Float)
  }


extension Color : Ingestible
  {
    public init(json: Any) throws
      {
        switch json {
          case let name as String :
            self = .named(name)
          case let values as [Float] where values.count == 3 :
            self = .rgba(values[0], values[1], values[2], 1)
          case let values as [Float] where values.count == 4 :
            self = .rgba(values[0], values[1], values[2], values[3])
          default :
            throw Exception("expecting color name or array of 3 or 4 component values")
        }
      }
  }
