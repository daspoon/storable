/*

  Created by David Spooner

*/

import Foundation


/// Exception is the custom Error type thrown by the components of this package.

public struct Exception : LocalizedError
  {
    public let errorDescription : String?
    public let failureReason : String?

    public init(_ reason: String)
      {
        errorDescription = nil
        failureReason = reason
      }

    public init(description d: String, failureReason r: String)
      {
        errorDescription = d
        failureReason = r
      }
  }


// Some convenience constructors.

extension Exception
  {
    public static func missingValue(key: String, in context: String?) -> Exception
      { .init("missing value for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }

    public static func illTypedValue<T>(key: String, type: T.Type, in context: String?) -> Exception
      { .init("expecting value of type \(T.self) for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }

    public static func illFormedValue(key: String, in context: String?) -> Exception
      { .init("failed to interpret value for '\(key)'" + (context.map({" of \($0)"}) ?? "")) }
  }
