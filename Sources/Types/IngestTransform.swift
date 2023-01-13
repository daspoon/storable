/*

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
