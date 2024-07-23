import UIKit
import Flutter
import workmanager

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "nz.t1d.carer.updateValues", frequency: NSNumber(value: 15 * 60))

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
