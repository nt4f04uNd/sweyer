import Flutter
import UIKit
import MediaPlayer

public class SweyerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "sweyer_plugin", binaryMessenger: registrar.messenger())
        let instance = SweyerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // The actual implementation is handled by the Dart side using the playify package
        // This Swift file is just a stub to register the plugin
        result(FlutterMethodNotImplemented)
    }
}
