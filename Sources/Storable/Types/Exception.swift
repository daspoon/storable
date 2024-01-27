/*

  Created by David Spooner

*/

import Foundation


/// Exception is the custom Error type thrown by the components of this package.

struct Exception : LocalizedError
  {
    let errorDescription : String?
    let failureReason : String?

    init(_ reason: String)
      {
        errorDescription = nil
        failureReason = reason
      }

    init(description d: String, failureReason r: String)
      {
        errorDescription = d
        failureReason = r
      }
  }


// Some convenience constructors.

extension Exception
  {
    static func missingValue(key: String, in context: String?) -> Exception
      { .init("missing value for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }

    static func illTypedValue<T>(key: String, type: T.Type, in context: String?) -> Exception
      { .init("expecting value of type \(T.self) for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }

    static func illFormedValue(key: String, in context: String?) -> Exception
      { .init("failed to interpret value for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }
  }
