/*

  Created by David Spooner

*/

import Foundation


/// An convenience protocol to reduce the boilerplate for defining CodingKey types which are essentially arbitrary strings.
public protocol StringCodingKey : CodingKey
  { }

extension StringCodingKey
  {
    public init?(intValue: Int)
      { nil }

    public var intValue : Int?
      { nil }

    public var description : String
      { stringValue }

    public var debugDescription : String
      { stringValue }
  }


extension StringCodingKey
  {
    public static func == (lhs: Self, rhs: Self) -> Bool
      { lhs.stringValue == rhs.stringValue }
  }


// MARK: -

/// A convenience type to enable using strings as coding keys.
public struct NameCodingKey : StringCodingKey, Equatable
  {
    public let name : String

    public init(name: String)
      { self.name = name }

    public init?(stringValue: String)
      { self.init(name: stringValue) }

    public var stringValue : String
      { name }
  }


// MARK: -

/// A convenience type to enable using URLs as coding keys.
public struct URLCodingKey : StringCodingKey, Equatable
  {
    public let url : URL

    public init(url: URL)
      { self.url = url }

    public init?(stringValue: String)
      {
        guard let url = URL(string: stringValue) else { return nil }
        self.init(url: url)
      }

    public var stringValue : String
      { url.absoluteString }
  }
