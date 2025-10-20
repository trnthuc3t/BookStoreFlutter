import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    ZaloPayMethodCallHandler.register(with: self.registrar(forPlugin: "ZaloPayMethodCallHandler")!)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
