import AVFoundation
import Flutter
import Foundation
#if os(iOS) || os(tvOS)
  import AVKit
  import UIKit
#endif

/// Where iOS is currently sending this app's audio, and the standard control
/// for changing it.
///
/// This exists because AirPlay is a *route*, not a player. Music Assistant
/// players are things the app addresses over a socket and can enumerate;
/// an AirPlay destination is chosen by the operating system on the app's
/// behalf and is never named to the app until after the fact. The only
/// supported way to let a user pick one is `AVRoutePickerView` — there is no
/// API that lists AirPlay receivers or selects one programmatically, and any
/// list this app drew itself would be a guess that goes stale.
///
/// So the plugin does exactly two things: it *reports* the route the session
/// ended up on, and it vends the system's own button as a platform view. The
/// picker's contents, ordering and pairing flow all stay Apple's.
///
/// The route is reported rather than controlled, which is why the Dart side
/// treats it as an observation and never as a command.
public class AudioRoutePlugin: NSObject, FlutterPlugin {
  /// Platform-view id for the embedded `AVRoutePickerView`.
  public static let routeButtonViewType = "com.plezy/airplay_route_button"

  private let events = RouteEventHandler()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/audio_route", binaryMessenger: registrar.messenger())
    let instance = AudioRoutePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    FlutterEventChannel(
      name: "com.plezy/audio_route/events", binaryMessenger: registrar.messenger()
    ).setStreamHandler(instance.events)

    #if os(iOS)
      registrar.register(
        RoutePickerViewFactory(), withId: AudioRoutePlugin.routeButtonViewType)
    #endif
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getRoute":
      result(AudioRoutePlugin.currentRoute())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// The session's current output as `{name, kind}`.
  ///
  /// Only the *first* output port is reported. A route with several outputs is
  /// possible in principle, but the name shown to the user has to be one
  /// string, and every multi-output case observed here (AirPlay to a stereo
  /// pair, for example) presents as one port whose name is already the thing
  /// the user recognises.
  static func currentRoute() -> [String: Any] {
    let session = AVAudioSession.sharedInstance()
    guard let port = session.currentRoute.outputs.first else {
      return ["name": "", "kind": "unknown"]
    }
    return ["name": port.portName, "kind": kind(of: port.portType)]
  }

  /// Collapse `AVAudioSession.Port` into the handful of distinctions a
  /// listener actually makes.
  ///
  /// `airPlay` is the one that carries a decision: it is the only route where
  /// the audio leaves the phone, which is exactly the difference the output
  /// picker exists to explain. The rest are folded to their nearest icon
  /// rather than enumerated, because nothing downstream branches on them
  /// beyond which glyph to draw.
  private static func kind(of port: AVAudioSession.Port) -> String {
    switch port {
    case .airPlay:
      return "airPlay"
    case .builtInSpeaker, .builtInReceiver:
      return "speaker"
    case .headphones, .headsetMic:
      return "headphones"
    case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
      return "bluetooth"
    case .carAudio:
      return "car"
    case .HDMI, .usbAudio, .lineOut:
      return "wired"
    default:
      return "unknown"
    }
  }
}

/// Streams the route to Dart on every change.
///
/// Polling would be the obvious alternative and is wrong here: a route change
/// is an event the system already publishes, and the interesting moment — the
/// instant after the user picks a destination in the system picker — is
/// precisely when a poll interval would show stale state on screen.
private class RouteEventHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?

  func onListen(withArguments _: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
    sink = eventSink
    NotificationCenter.default.addObserver(
      self, selector: #selector(routeChanged),
      name: AVAudioSession.routeChangeNotification, object: nil)
    // Emit once on subscribe so a listener that attaches after the route
    // settled still learns what it is, rather than waiting for a change that
    // may never come.
    eventSink(AudioRoutePlugin.currentRoute())
    return nil
  }

  func onCancel(withArguments _: Any?) -> FlutterError? {
    NotificationCenter.default.removeObserver(
      self, name: AVAudioSession.routeChangeNotification, object: nil)
    sink = nil
    return nil
  }

  @objc private func routeChanged(_: Notification) {
    // The notification arrives on an arbitrary queue and the sink must be
    // touched from the platform thread.
    DispatchQueue.main.async { [weak self] in
      self?.sink?(AudioRoutePlugin.currentRoute())
    }
  }
}

#if os(iOS)
  /// Vends the real system route button into the Flutter view hierarchy.
  ///
  /// Embedding Apple's own control, rather than drawing a lookalike that calls
  /// through to native code, is what makes the button behave the way it does
  /// everywhere else on the phone: it carries the system's active-route
  /// animation, and its picker is presented by the OS with no app involvement.
  private class RoutePickerViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(withFrame frame: CGRect, viewIdentifier _: Int64, arguments args: Any?)
      -> FlutterPlatformView
    {
      RoutePickerPlatformView(frame: frame, arguments: args as? [String: Any])
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
      FlutterStandardMessageCodec.sharedInstance()
    }
  }

  private class RoutePickerPlatformView: NSObject, FlutterPlatformView {
    private let picker: AVRoutePickerView

    init(frame: CGRect, arguments: [String: Any]?) {
      picker = AVRoutePickerView(frame: frame)
      picker.backgroundColor = .clear
      // Tinted from Dart so the button reads as part of the sheet it sits in.
      // `activeTintColor` is what the system uses while a route is engaged, and
      // leaving it at the default made an engaged AirPlay button invisible
      // against this app's dark surface.
      if let tint = arguments?["tint"] as? NSNumber {
        picker.tintColor = RoutePickerPlatformView.color(from: tint.intValue)
      }
      if let active = arguments?["activeTint"] as? NSNumber {
        picker.activeTintColor = RoutePickerPlatformView.color(from: active.intValue)
      }
      // Audio only: this app's video path has its own route handling, and
      // offering video destinations from the music output picker would list
      // TVs that the music engine cannot reach.
      picker.prioritizesVideoDevices = false
      super.init()
    }

    func view() -> UIView { picker }

    private static func color(from argb: Int) -> UIColor {
      UIColor(
        red: CGFloat((argb >> 16) & 0xFF) / 255.0,
        green: CGFloat((argb >> 8) & 0xFF) / 255.0,
        blue: CGFloat(argb & 0xFF) / 255.0,
        alpha: CGFloat((argb >> 24) & 0xFF) / 255.0)
    }
  }
#endif
