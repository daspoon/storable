/*

  Created by David Spooner

*/


/// IngestTransform provides a means for managed properties to be ingested from types other than their declared type.

public protocol IngestTransform
  {
    /// The input type of the transform
    associatedtype Input

    /// The output type of the transform
    associatedtype Output

    /// Transform an input value to an output value, throwing on failure.
    func transform(_ input: Input) throws -> Output
  }


public struct StringToFloat : IngestTransform
  {
    public init() {}

    public func transform(_ stringValue: String) throws -> Float
      {
        guard let floatValue = Float(stringValue) else { throw Exception("expecting floating-point value") }
        return floatValue
      }
  }
