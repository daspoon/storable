/*

*/


func throwingCast<T>(_ v: Any, as: T.Type = T.self) throws -> T
  {
    guard let t = v as? T else { throw Exception("expecting value of type \(T.self)") }
    return t
  }
