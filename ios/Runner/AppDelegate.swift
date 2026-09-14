import Flutter
import UIKit
import home_widget

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // Register for home_widget callbacks
    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }
    
    // Check for widget actions
    checkForWidgetActions()
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  func checkForWidgetActions() {
    let userDefaults = UserDefaults(suiteName: "group.com.nt4f04und.sweyer")
    if let actionString = userDefaults?.string(forKey: "widgetAction") {
      userDefaults?.removeObject(forKey: "widgetAction")
      userDefaults?.synchronize()
      
      if let url = URL(string: actionString),
         url.host == "widget",
         ["playPause", "next", "previous"].contains(url.lastPathComponent),
         let controller = window?.rootViewController as? FlutterViewController {
        let channel = FlutterMethodChannel(
          name: "com.nt4f04und.sweyer/player_controls",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod(url.lastPathComponent, arguments: nil)
      }
    }
  }
}
