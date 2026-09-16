import UIKit

final class ExternalDisplayManager {
  static let shared = ExternalDisplayManager()

  private weak var activeCore: MpvPlayerCore?
  private var externalScene: UIWindowScene?
  private var externalWindow: UIWindow?
  private var externalRootViewController: UIViewController?

  private init() {}

  static func isExternalDisplayRole(_ role: UISceneSession.Role) -> Bool {
    role.rawValue == "UIWindowSceneSessionRoleExternalDisplay"
      || role.rawValue == "UIWindowSceneSessionRoleExternalDisplayNonInteractive"
  }

  static var hasActiveApplicationScene: Bool {
    applicationWindowScenes.contains { $0.activationState == .foregroundActive }
  }

  static func mainApplicationWindow() -> UIWindow? {
    let scenes = applicationWindowScenes.sorted {
      scenePriority($0.activationState) < scenePriority($1.activationState)
    }

    for scene in scenes {
      if let window = scene.windows.first(where: { $0.isKeyWindow }) {
        return window
      }
    }

    for scene in scenes {
      if let window = scene.windows.first(where: { !$0.isHidden }) {
        return window
      }
    }

    return scenes.first?.windows.first
  }

  private static var applicationWindowScenes: [UIWindowScene] {
    UIApplication.shared.connectedScenes.compactMap { scene in
      guard let windowScene = scene as? UIWindowScene,
        !isExternalDisplayRole(windowScene.session.role)
      else { return nil }
      return windowScene
    }
  }

  private static func scenePriority(_ state: UIScene.ActivationState) -> Int {
    switch state {
    case .foregroundActive:
      return 0
    case .foregroundInactive:
      return 1
    case .background:
      return 2
    case .unattached:
      return 3
    @unknown default:
      return 4
    }
  }

  var videoSuperview: UIView? {
    externalRootViewController?.view
  }

  func attach(core: MpvPlayerCore) {
    activeCore = core
    discoverExistingExternalScene()
    activeCore?.externalDisplayDidChange()
  }

  func detach(core: MpvPlayerCore) {
    if activeCore === core {
      activeCore = nil
    }
  }

  @discardableResult
  func connect(scene: UIWindowScene) -> UIWindow? {
    guard Self.isExternalDisplayRole(scene.session.role) else { return nil }

    externalScene = scene
    let window = ensureWindow(for: scene)
    activeCore?.externalDisplayDidChange()
    MpvLog.debug("[ExternalDisplayManager] External display connected")
    return window
  }

  func disconnect(scene: UIScene) {
    guard scene === externalScene else { return }

    externalWindow?.isHidden = true
    externalWindow = nil
    externalRootViewController = nil
    externalScene = nil
    activeCore?.externalDisplayDidChange()
    MpvLog.debug("[ExternalDisplayManager] External display disconnected")
  }

  func update(scene: UIWindowScene) {
    guard scene === externalScene else { return }
    externalRootViewController?.view.frame = scene.coordinateSpace.bounds
    activeCore?.externalDisplayDidChange()
  }

  private func discoverExistingExternalScene() {
    guard externalScene == nil else { return }

    for scene in UIApplication.shared.connectedScenes {
      guard let windowScene = scene as? UIWindowScene,
        Self.isExternalDisplayRole(windowScene.session.role)
      else { continue }
      _ = connect(scene: windowScene)
      return
    }
  }

  private func ensureWindow(for scene: UIWindowScene) -> UIWindow {
    if let existing = externalWindow, existing.windowScene === scene {
      return existing
    }

    externalWindow?.isHidden = true

    let rootViewController = UIViewController()
    rootViewController.view.frame = scene.coordinateSpace.bounds
    rootViewController.view.backgroundColor = .black

    let window = UIWindow(windowScene: scene)
    window.rootViewController = rootViewController
    window.backgroundColor = .black
    window.isHidden = false

    externalRootViewController = rootViewController
    externalWindow = window
    return window
  }
}

class ExternalDisplaySceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene,
      ExternalDisplayManager.isExternalDisplayRole(session.role)
    else { return }

    window = ExternalDisplayManager.shared.connect(scene: windowScene)
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    ExternalDisplayManager.shared.disconnect(scene: scene)
    window = nil
  }

  func windowScene(
    _ windowScene: UIWindowScene,
    didUpdate previousCoordinateSpace: UICoordinateSpace,
    interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
    traitCollection previousTraitCollection: UITraitCollection
  ) {
    ExternalDisplayManager.shared.update(scene: windowScene)
  }
}
