/*

*/


enum Choice<Object: Named>
  {
    case resolved(Object)
    case unresolved(String)

    var name : String
      {
        switch self {
          case .resolved(let object) : return object.name
          case .unresolved(let name) : return name
        }
      }

    var element : Object?
      {
        switch self {
          case .resolved(let object) : return object
          case .unresolved : return nil
        }
      }

    var isResolved : Bool
      {
        switch self {
          case .resolved : return true
          case .unresolved : return false
        }
      }
  }
