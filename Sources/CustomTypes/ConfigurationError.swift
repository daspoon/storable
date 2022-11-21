/*

*/

import Foundation


enum ConfigurationError : Error
  {
    case resourceComponentTypeError(name: String, path: String, expectedType: String)
    case invalidEntity(name: String)
    case unknownObject(name: String, entityName: String)
    case ambigousObject(predicate: NSPredicate?, entityName: String)
    case missingAttributeValue(key: String, context: String?=nil)
    case illTypedAttributeValue(key: String, context: String?=nil, expectedType: String)
    case invalidAttributeValue(key: String, context: String?=nil)
    case dataIntegrityError(String)

    var localizedDescription : String
      {
        switch self {
          case .resourceComponentTypeError(name: let name, path: let path, expectedType: let type) :
            return "Element '\(path)' of '\(name).json' is not of the expected type '\(type)'"
          case .invalidEntity(name: let name) :
            return "Invalid entity '\(name)'"
          case .unknownObject(name: let objectName, entityName: let entityName) :
            return "Unknown object '\(objectName)' of entity '\(entityName)'"
          case .ambigousObject(predicate: let predicate, entityName: let entityName) :
          return "Multiple matches for '\(entityName)' satisfying '\(String(describing: predicate))'"
          case .missingAttributeValue(key: let key, context: let context) :
            return "Missing value for attribute '\(key)'" + (context.map({" of \($0)"}) ?? "")
          case .illTypedAttributeValue(key: let key, context: let context, expectedType: let expectedType) :
            return "Type for attribute '\(key)'" + (context.map({" of \($0)"}) ?? "") + " must be '\(expectedType)'"
          case .invalidAttributeValue(key: let key, context: let context) :
            return "Invalid value for attribute '\(key)'" + (context.map({" of \($0)"}) ?? "")
          case .dataIntegrityError(let description) :
            return description
        }
      }
  }
