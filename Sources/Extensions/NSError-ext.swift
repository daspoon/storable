/*

*/

import Foundation


extension NSError
  {
    public convenience init(bundle: Bundle = .main, code: Int = -1, failureReason: String)
      {
        self.init(domain: bundle.bundleIdentifier ?? "?", code: code, userInfo: [
          NSLocalizedFailureReasonErrorKey : failureReason,
        ])
      }
  }
