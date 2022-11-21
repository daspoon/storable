/*

*/

import UIKit


/// Intended for adoption by UIViewControllers residing in a UITabBarController.
public protocol TabBarCompatible
  {
    var tabBarTitle : String { get }
    var tabBarImage : UIImage? { get }
  }
