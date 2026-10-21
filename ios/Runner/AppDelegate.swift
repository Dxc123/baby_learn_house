import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let drawingShare = DrawingShareHandler()
  private var drawingChannel: FlutterMethodChannel?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DrawingShare")!
    let channel = FlutterMethodChannel(name: "baby_learn_house/drawing_share", binaryMessenger: registrar.messenger())
    drawingChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "sharePng" else { result(FlutterMethodNotImplemented); return }
      guard let self = self else { result(FlutterError(code: "unavailable", message: nil, details: nil)); return }
      self.drawingShare.share(call.arguments, presenter: registrar.viewController, result: result)
    }
  }
}
