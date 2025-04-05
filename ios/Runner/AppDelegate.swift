import Flutter
import UIKit
import home_widget

@UIApplicationMain
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
      
      if let url = URL(string: actionString), let host = url.host {
        if host == "widget" {
          let action = url.lastPathComponent
          var methodName = ""
          
          switch action {
          case "playPause":
            methodName = "togglePlayPause"
          case "next":
            methodName = "skipToNext"
          case "previous":
            methodName = "skipToPrevious"
          default:
            break
          }
          
          if !methodName.isEmpty {
            // Send the action to Flutter via method channel
            let controller = window?.rootViewController as? FlutterViewController
            let channel = FlutterMethodChannel(name: "com.nt4f04und.sweyer/player_controls", 
                                              binaryMessenger: controller!.binaryMessenger)
            channel.invokeMethod(methodName, arguments: nil)
          }
        }
      }
    }
  }
}
