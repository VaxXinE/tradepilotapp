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
    LiveChatBridge.register(messenger: engineBridge.applicationRegistrar.messenger())
    let clipboardChannel = FlutterMethodChannel(
      name: "id.tradepilot.app/clipboard",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    clipboardChannel.setMethodCallHandler { call, result in
      guard call.method == "copyImage",
            let bytes = call.arguments as? FlutterStandardTypedData,
            let image = UIImage(data: bytes.data) else {
        result(FlutterMethodNotImplemented)
        return
      }
      UIPasteboard.general.image = image
      result(nil)
    }
  }
}
