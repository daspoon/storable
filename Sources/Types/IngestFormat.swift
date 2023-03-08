/*

*/


/// IngestFormat determines how to interpret the json data provided on object ingestion.

public enum IngestFormat
  {
    /// An arbitrary value
    case any
    /// An array of arbitrary values
    case array
    /// A dictionary mapping string keys to arbitrary values
    case dictionary
    /// An array of strings interpreted as a dictionary mapping the elements to an empty dictionary (or an arbitrary value?).
    case dictionaryAsArrayOfKeys
  }
