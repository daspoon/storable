/*

*/


public protocol IngestTransform
  {
    associatedtype Input
    associatedtype Output

    func validate(_ input: Any) throws -> Input

    func transform(_ input: Input) throws -> Output
  }
