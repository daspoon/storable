/*

  Created by David Spooner

*/

import CoreData


extension NSDeleteRule
  {
    init(_ rule: RelationshipInfo.DeleteRule)
      {
        switch rule {
          case .noAction : self = .noActionDeleteRule
          case .nullify  : self = .nullifyDeleteRule
          case .cascade  : self = .cascadeDeleteRule
          case .deny     : self = .denyDeleteRule
        }
      }
  }
