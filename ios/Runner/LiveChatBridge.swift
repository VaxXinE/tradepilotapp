import Combine
import Flutter
import PhotosUI
import SolidChatSDK
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Flutter <-> SolidChat SDK bridge (`id.tradepilot.app/live_chat`).
/// The chat UI is the SDK's native SwiftUI `SolidChatView`; Flutter only opens it.
enum LiveChatBridge {
  static let channelName = "id.tradepilot.app/live_chat"

  /// Production defaults; the iOS SDK has none of its own.
  static let apiURL = URL(string: "https://live-chat.sg-berjangka.com")!
  static let siteId = "solid-gold-main"

  /// Backend-issued identity JWT waiting for the next chat session.
  private static var identityToken: String?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "open":
        let args = call.arguments as? [String: Any]
        let language = args?["language"] as? String ?? "id"
        DispatchQueue.main.async {
          guard let presenter = topViewController() else {
            result(FlutterError(code: "no_presenter", message: "No view controller to present from", details: nil))
            return
          }
          let controller = LiveChatViewController(language: language, identityToken: identityToken)
          controller.modalPresentationStyle = .fullScreen
          presenter.present(controller, animated: true)
          result(nil)
        }
      case "identify":
        let args = call.arguments as? [String: Any]
        let token = (args?["token"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        identityToken = (token?.isEmpty == false) ? token : nil
        result(nil)
      case "reset":
        identityToken = nil
        DispatchQueue.main.async {
          // Clears the persisted visitor/conversation for the default site.
          Task { @MainActor in
            SolidChatClient(configuration: .init(apiURL: apiURL, siteId: siteId)).reset()
          }
          result(nil)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var top = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }
}

/// Owns one `SolidChatClient` for the lifetime of a single chat screen.
@MainActor
private final class LiveChatViewController: UIViewController, PHPickerViewControllerDelegate {
  private let client: SolidChatClient
  private let identityToken: String?
  private var identifyCancellable: AnyCancellable?
  private var pendingImage: CheckedContinuation<SolidChatImage?, Never>?

  init(language: String, identityToken: String?) {
    client = SolidChatClient(
      configuration: .init(apiURL: LiveChatBridge.apiURL, siteId: LiveChatBridge.siteId, language: language)
    )
    self.identityToken = identityToken
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor(red: 0.035, green: 0.035, blue: 0.043, alpha: 1)
    // The SDK view hardcodes a dark background; keep system controls dark to match.
    overrideUserInterfaceStyle = .dark

    let chat = SolidChatView(
      client: client,
      imageProvider: { [weak self] in await self?.pickImage() },
      onClose: { [weak self] in self?.dismiss(animated: true) }
    )
    let host = UIHostingController(rootView: chat)
    addChild(host)
    host.view.frame = view.bounds
    host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    view.addSubview(host.view)
    host.didMove(toParent: self)

    identifyWhenReady()
  }

  /// Identity can only be attached once the SDK has a visitor session.
  private func identifyWhenReady() {
    guard let token = identityToken else { return }
    identifyCancellable = client.$state
      .first { $0.site != nil }
      .sink { [weak self] _ in
        guard let client = self?.client else { return }
        Task { try? await client.identify(identityToken: token) }
      }
  }

  private func pickImage() async -> SolidChatImage? {
    await withCheckedContinuation { continuation in
      var config = PHPickerConfiguration()
      config.filter = .images
      config.selectionLimit = 1
      let picker = PHPickerViewController(configuration: config)
      picker.delegate = self
      pendingImage = continuation
      (presentedViewController ?? self).present(picker, animated: true)
    }
  }

  nonisolated func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    Task { @MainActor in
      picker.dismiss(animated: true)
      let continuation = pendingImage
      pendingImage = nil
      guard let provider = results.first?.itemProvider,
            provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) else {
        continuation?.resume(returning: nil)
        return
      }
      let data = await Self.loadImageData(from: provider)
      // Re-encode to JPEG so HEIC/PNG uploads always match the declared MIME type.
      guard let data, let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) else {
        continuation?.resume(returning: nil)
        return
      }
      continuation?.resume(returning: SolidChatImage(
        data: jpeg,
        fileName: "livechat_\(Int(Date().timeIntervalSince1970)).jpg",
        mimeType: "image/jpeg"
      ))
    }
  }

  private static func loadImageData(from provider: NSItemProvider) async -> Data? {
    await withCheckedContinuation { continuation in
      provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
        continuation.resume(returning: data)
      }
    }
  }

  deinit {
    // Unblock a pending picker request if the screen goes away mid-selection.
    pendingImage?.resume(returning: nil)
  }
}
