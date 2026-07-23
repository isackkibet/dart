import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let pipBridge = YohPalPiPBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    pipBridge.register(with: controller.binaryMessenger)
    GeneratedPluginRegistrant.register(with: self)
    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }
}
