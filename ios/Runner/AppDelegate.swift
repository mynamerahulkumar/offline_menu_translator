import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func initModel() {
      // Construct path to the model file
      let fileManager = FileManager.default
      // Ensure we unwrap safely or handle missing dict
      if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
          let modelPath = documentsPath.appendingPathComponent("gemma-2b-it-cpu-int4.bin")

          // Check if model exists before initializing
          if !fileManager.fileExists(atPath: modelPath.path) {
              print("Gemma model is not installed yet. Use the model manager to load model first")
              return
          }
      }

      do {
          // ...existing code...
      } catch {
          print("Failed to Initialize AI model: \(error)")
      }
  }
}
