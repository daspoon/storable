/*

  Created by David Spooner

*/

import Foundation


extension URL
  {
    enum CoreDataResidenceType
      { case permanent, temporary }

    static var coreDataScheme : String
      { "x-coredata" }

    private var coreDataPathComponents : (entityName: String, residenceId: String)?
      {
        guard scheme == .some(Self.coreDataScheme), pathComponents.count == 3, pathComponents[0] == "/" else { return nil }
        return (pathComponents[1], pathComponents[2])
      }

    var coreDataResidenceType : CoreDataResidenceType?
      {
        guard let coreDataPathComponents else { return nil }
        return coreDataPathComponents.residenceId.hasPrefix("t") ? .temporary : .permanent
      }

    var coreDataEntityName : String?
      { coreDataPathComponents?.entityName }
  }


extension URL
  {
    public func withSecurityScopedAccess(execute block: (URL) throws -> Void) throws
      {
        guard startAccessingSecurityScopedResource() else { throw Exception("failed to access \(self)") }
        defer { stopAccessingSecurityScopedResource() }
        try block(self)
      }
  }
