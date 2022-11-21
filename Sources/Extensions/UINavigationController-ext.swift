/*

*/

import UIKit


public extension UINavigationController
  {
    public var penultimateViewController : UIViewController?
      {
        guard viewControllers.count >= 2 else { return nil }
        return viewControllers[viewControllers.count - 2]
      }

    public func pushViewController(_ controller: UIViewController, animated: Bool, completion: @escaping () -> Void)
      {
        // adapted from https://stackoverflow.com/a/33767837
        pushViewController(controller, animated: animated)

        if animated {
          guard let transitionCoordinator else { preconditionFailure("unexpected state") }
          transitionCoordinator.animate(alongsideTransition: nil) { _ in completion() }
        }
        else {
          DispatchQueue.main.async { completion() }
        }
      }
  }

