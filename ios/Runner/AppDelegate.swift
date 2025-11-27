import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let screenshotChannel = FlutterMethodChannel(name: "screenshot_protection",
                                              binaryMessenger: controller.binaryMessenger)
    
    screenshotChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "enable" {
        // iOS doesn't support preventing screenshots, but we can detect them
        // For now, we'll just return success
        result(true)
      } else if call.method == "disable" {
        result(true)
      } else if call.method == "setSecureFlag" {
        let enable = (call.arguments as? [String: Any])?["enable"] as? Bool ?? false
        // iOS doesn't support FLAG_SECURE equivalent
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
