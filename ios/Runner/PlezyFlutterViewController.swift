import Flutter
import UIKit

/// Root view controller (set in Main.storyboard). Bridges the iPhone Duo
/// layout signals Flutter does not expose on iOS — the edge holding the
/// system's vertical bar, the hinge, and the reserved regions (fold and
/// camera/status occlusions) — over `com.plezy/iphone_duo`, and lets Dart
/// opt the video player out of the vertical bar.
///
/// All geometry is in this view's coordinate space, which is Flutter's
/// logical pixel space.
class PlezyFlutterViewController: FlutterViewController {
  private var duoChannel: FlutterMethodChannel?
  private var verticalBarDisabled = false
  private var hingeStatus: String?
  private var lastState: NSDictionary?

  override func viewDidLoad() {
    super.viewDidLoad()

    let channel = FlutterMethodChannel(name: "com.plezy/iphone_duo", binaryMessenger: binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
    duoChannel = channel

    if #available(iOS 27.1, *) {
      registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) {
        (self: Self, _: UITraitCollection) in
        self.pushStateIfChanged()
      }

      let hinge = UIHingeInteraction { [weak self] _, update in
        guard let self else { return }
        if let hinge = update.hinge {
          self.hingeStatus = Self.name(of: hinge.status)
        } else {
          self.hingeStatus = nil
        }
        // Reserved regions follow the hinge; read them after the resulting layout.
        self.view.setNeedsLayout()
        self.pushStateIfChanged()
      }
      view.addInteraction(hinge)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    pushStateIfChanged()
  }

  @available(iOS 27.1, *)
  override var preferredVerticalBarBehavior: UIVerticalBarBehavior {
    verticalBarDisabled ? .disabled : .automatic
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getState":
      let state = currentState()
      lastState = state
      result(state)
    case "setVerticalBarDisabled":
      let disabled = (call.arguments as? Bool) ?? false
      if disabled != verticalBarDisabled {
        verticalBarDisabled = disabled
        if #available(iOS 27.1, *) {
          setNeedsUpdateOfVerticalBarConfiguration()
        }
      }
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func pushStateIfChanged() {
    guard let duoChannel, isViewLoaded else { return }
    let state = currentState()
    if let lastState, lastState.isEqual(state) { return }
    lastState = state
    duoChannel.invokeMethod("stateChanged", arguments: state)
  }

  private func currentState() -> NSDictionary {
    var state: [String: Any] = [:]
    guard #available(iOS 27.1, *) else { return state as NSDictionary }

    switch traitCollection.verticalBarEdge {
    case .leading:
      state["verticalBarEdge"] = isRightToLeft ? "right" : "left"
    case .trailing:
      state["verticalBarEdge"] = isRightToLeft ? "left" : "right"
    default:
      break
    }

    if let hingeStatus { state["hingeStatus"] = hingeStatus }

    state["folds"] = view.reservedRegions(kind: .division)
      .filter { $0.isActive && !$0.frame.isEmpty }
      .map { Self.encode($0.frame) }
    state["occlusions"] = view.reservedRegions(kind: .occlusion)
      .filter { $0.isActive && !$0.frame.isEmpty }
      .map { Self.encode($0.frame) }

    return state as NSDictionary
  }

  private var isRightToLeft: Bool {
    view.effectiveUserInterfaceLayoutDirection == .rightToLeft
  }

  private static func encode(_ rect: CGRect) -> [String: Double] {
    ["x": Double(rect.minX), "y": Double(rect.minY), "width": Double(rect.width), "height": Double(rect.height)]
  }

  @available(iOS 27.1, *)
  private static func name(of status: UIHinge.Status) -> String {
    switch status {
    case .closed: return "closed"
    case .partiallyOpen: return "partiallyOpen"
    case .fullyOpen: return "fullyOpen"
    default: return "unknown"
    }
  }
}
