import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // ── Google Maps iOS SDK ────────────────────────────────────────────────
    // IMPORTANTE: Substitua pela sua Google Maps API Key para iOS.
    // Obtenha em: https://console.cloud.google.com/google/maps-apis
    GMSServices.provideAPIKey("AIzaSyACObRioiZOzMv5nJsHEkxB8-QZRFKncxM")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
