import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "aesthetic_camera/flashlight",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      do {
        switch call.method {
        case "hasTorch":
          result(Self.torchDevice()?.hasTorch ?? false)
        case "supportsIntensity":
          result(Self.torchDevice()?.hasTorch ?? false)
        case "setEnabled":
          let enabled = (call.arguments as? [String: Any])?["enabled"] as? Bool ?? false
          try Self.setTorch(enabled: enabled, intensity: 0.8)
          result(nil)
        case "setIntensity":
          let intensity = (call.arguments as? [String: Any])?["intensity"] as? Double ?? 0.8
          try Self.setTorch(enabled: true, intensity: intensity)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "FLASHLIGHT", message: error.localizedDescription, details: nil))
      }
    }
  }

  private static func torchDevice() -> AVCaptureDevice? {
    AVCaptureDevice.default(for: .video)
  }

  private static func setTorch(enabled: Bool, intensity: Double) throws {
    guard let device = torchDevice(), device.hasTorch else {
      throw NSError(domain: "flashlight", code: 1, userInfo: [NSLocalizedDescriptionKey: "No flashlight on this device."])
    }
    try device.lockForConfiguration()
    if enabled {
      let level = Float(max(0.1, min(intensity, Double(AVCaptureDevice.maxAvailableTorchLevel))))
      try device.setTorchModeOn(level: level)
    } else {
      device.torchMode = .off
    }
    device.unlockForConfiguration()
  }
}
