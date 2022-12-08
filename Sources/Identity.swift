/*

*/


/// The notion of Object instance identity.
public enum Identity : String, Ingestible
  {
    /// There is no inherent identity.
    case anonymous

    /// Identity is given by the string value of the 'name' attribute.
    case name

    /// There is a single instance of the entity.
    case singleton
  }
