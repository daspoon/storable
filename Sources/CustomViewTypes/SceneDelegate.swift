/*

*/

import UIKit


/// SceneDelegate creates a window with a tab bar as its root view controller, and populates that tab bar with a subclass-defined list of view controllers; these view controllers
/// are implicitly wrapped in navigation controllers.
///
open class SceneDelegate : UIResponder, UIWindowSceneDelegate
  {
    public var window : UIWindow?


    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions)
      {
        guard let scene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(frame: scene.coordinateSpace.bounds)
        let tabBarController = UITabBarController()
        let topLevelViewControllers = createTopLevelViewControllers()
        let navigationControllers = topLevelViewControllers.enumerated().map { i, topLevelViewController in
          topLevelViewController.tabBarItem = UITabBarItem(title: topLevelViewController.tabBarTitle, image: topLevelViewController.tabBarImage, tag: i)
          return UINavigationController(rootViewController: topLevelViewController)
        }
        tabBarController.setViewControllers(navigationControllers, animated: false)
        window.rootViewController = tabBarController
        window.windowScene = scene
        window.makeKeyAndVisible()

        self.window = window
      }


    /// Create the view controllers which will appear as tabs.
    open func createTopLevelViewControllers() -> [UIViewController & TabBarCompatible]
      {
        preconditionFailure("subclass responsibility")
      }

  }
