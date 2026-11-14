import Flutter
import Foundation
import Network

/// Browses the local network for Bonjour services, using Apple's own API.
///
/// ### Why this exists at all
///
/// Discovery was written on `package:multicast_dns`, which opens a raw UDP
/// socket to 224.0.0.251:5353 and speaks mDNS itself. That works on macOS, on
/// Android, and — decisively — in the iOS **simulator**, which is why an
/// end-to-end run there resolved the real server and proved nothing.
///
/// On an iOS *device* it silently finds nothing. Since iOS 14 a raw
/// multicast or broadcast socket requires the
/// `com.apple.developer.networking.multicast` entitlement, which Apple grants
/// only on request. Without it the socket does not fail, does not error and
/// does not close: it simply never receives a datagram. There is no signal to
/// log and nothing to catch, which is exactly why the failure reads as "the
/// server isn't there" rather than as a permissions problem.
///
/// `NWBrowser` needs no such entitlement. It asks `mDNSResponder` — the daemon
/// already doing this work for the whole system — instead of putting a second
/// mDNS implementation on the wire. The cost of admission is declaring the
/// service type in `NSBonjourServices`, which this app already does, plus the
/// ordinary local-network permission.
///
/// So the entitlement is deliberately *not* pursued: it would mean an Apple
/// approval round for permission to reimplement a daemon that is already
/// running.
///
/// ### What it deliberately does not do
///
/// It does not know what Music Assistant is. It returns the instance name, the
/// TXT pairs and a resolved host and port, and every judgement about what that
/// means — whether the address is plausibly on the LAN, which field is the
/// server id, what to call the thing — stays in Dart where it already lives
/// and is already tested. A native path that reimplemented those rules would
/// be a second place for them to drift.
public class BonjourDiscoveryPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "com.plezy/bonjour_discovery", binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(BonjourDiscoveryPlugin(), channel: channel)
  }

  /// Browsers are held for the life of a call only. Kept as a property because
  /// `NWBrowser` stops the moment it is deallocated, and a local would be
  /// released the instant `browse` returned — which is before any result has
  /// arrived.
  private var browsers: [UUID: NWBrowser] = [:]
  private let lock = NSLock()

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "browse":
      guard let args = call.arguments as? [String: Any], let type = args["type"] as? String else {
        result(FlutterError(code: "bad_args", message: "type is required", details: nil))
        return
      }
      // Every path out of `browse` finishes through this, and it is the only
      // place a `FlutterResult` is invoked.
      //
      // Flutter requires that a result be delivered on the platform thread.
      // The browse finishes on a background queue — it has to, the whole thing
      // is timers and connection callbacks — and replying from there wedged
      // the engine hard enough that the app rendered no further frames,
      // accepted no touches or keystrokes, and could not be recovered by
      // force-quitting: the first screen shown on launch browses, so every
      // relaunch walked straight back into it.
      //
      // It is also latched. `NWConnection` state handlers and the timeout that
      // races them can both fire, and a second reply on a method channel is a
      // fatal error rather than a no-op.
      let replied = NSLock()
      var done = false
      let reply: (Any?) -> Void = { payload in
        replied.lock()
        if done {
          replied.unlock()
          return
        }
        done = true
        replied.unlock()
        DispatchQueue.main.async { result(payload) }
      }
      let browseMs = args["browseTimeoutMs"] as? Int ?? 2500
      let resolveMs = args["resolveTimeoutMs"] as? Int ?? 1500
      // Defence in depth against the same class of failure. Every internal
      // path is individually bounded, but a method channel that never replies
      // is indistinguishable from a hung app, so the reply is guaranteed by a
      // deadline rather than by the correctness of the code beneath it.
      DispatchQueue.global(qos: .userInitiated)
        .asyncAfter(deadline: .now() + .milliseconds(browseMs + resolveMs + 2000)) {
          reply([])
        }
      browse(type: type, browseMs: browseMs, resolveMs: resolveMs, result: reply)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Browse for [browseMs], then resolve what answered, then reply once.
  ///
  /// Two phases with separate budgets, matching the Dart implementation this
  /// replaces. They cannot share one: the browse always runs to the end of its
  /// window — there is no way to know how many responders are out there — so a
  /// shared deadline would leave resolution nothing to spend.
  private func browse(type: String, browseMs: Int, resolveMs: Int, result: @escaping (Any?) -> Void) {
    let token = UUID()
    let parameters = NWParameters()
    // A server reachable only over an AWDL peer-to-peer link is not a case
    // this app has, and including it makes the browse noticeably slower to
    // settle for no benefit.
    parameters.includePeerToPeer = false

    let browser = NWBrowser(
      for: .bonjourWithTXTRecord(type: type, domain: nil), using: parameters)

    var discovered: [String: (endpoint: NWEndpoint, txt: [String: String])] = [:]
    let found = NSLock()

    browser.browseResultsChangedHandler = { results, _ in
      for candidate in results {
        guard case let .service(name, _, _, _) = candidate.endpoint else { continue }
        var txt: [String: String] = [:]
        if case let .bonjour(record) = candidate.metadata {
          for entry in record {
            switch entry.value {
            case .string(let value):
              txt[entry.key] = value
            case .data(let value):
              txt[entry.key] = String(data: value, encoding: .utf8) ?? ""
            case .empty:
              txt[entry.key] = ""
            case .none:
              break
            @unknown default:
              break
            }
          }
        }
        found.lock()
        // Keyed by instance name so a service that is re-announced mid-browse
        // is one entry, not two.
        discovered[name] = (candidate.endpoint, txt)
        found.unlock()
      }
    }

    lock.lock()
    browsers[token] = browser
    lock.unlock()
    browser.start(queue: .global(qos: .userInitiated))

    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(browseMs)) {
      [weak self] in
      browser.cancel()
      self?.lock.lock()
      self?.browsers.removeValue(forKey: token)
      self?.lock.unlock()

      found.lock()
      let services = discovered
      found.unlock()

      guard !services.isEmpty else {
        result([])
        return
      }

      var payload: [[String: Any]] = []
      let collect = NSLock()
      let group = DispatchGroup()

      for (name, service) in services {
        group.enter()
        Self.resolve(endpoint: service.endpoint, timeoutMs: resolveMs) { host, port in
          collect.lock()
          // A service that would not resolve is still reported, with its TXT.
          // The advert carries `base_url`, and Dart already prefers a resolved
          // address and falls back to that — dropping it here would remove a
          // fallback that layer is written to use.
          payload.append([
            "name": name,
            "txt": service.txt,
            "host": host as Any,
            "port": port as Any,
          ])
          collect.unlock()
          group.leave()
        }
      }

      group.notify(queue: .global(qos: .userInitiated)) {
        result(payload)
      }
    }
  }

  /// Turn a Bonjour service endpoint into a host and port.
  ///
  /// Network.framework offers no "resolve only" call: an `NWConnection` that
  /// reaches `.ready` is what publishes the resolved address on its path. The
  /// connection is cancelled the moment that address is read, so this costs a
  /// TCP handshake to a port the caller is about to open anyway.
  private static func resolve(
    endpoint: NWEndpoint, timeoutMs: Int, completion: @escaping (String?, Int?) -> Void
  ) {
    let connection = NWConnection(to: endpoint, using: .tcp)
    let once = NSLock()
    var finished = false

    func finish(_ host: String?, _ port: Int?) {
      once.lock()
      if finished {
        once.unlock()
        return
      }
      finished = true
      once.unlock()
      connection.cancel()
      completion(host, port)
    }

    connection.stateUpdateHandler = { state in
      switch state {
      case .ready:
        guard case let .hostPort(host, port)? = connection.currentPath?.remoteEndpoint else {
          finish(nil, nil)
          return
        }
        finish(Self.describe(host), Int(port.rawValue))
      case .failed, .cancelled:
        finish(nil, nil)
      default:
        break
      }
    }
    connection.start(queue: .global(qos: .userInitiated))
    DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + .milliseconds(timeoutMs)) {
      finish(nil, nil)
    }
  }

  /// The address as a bare literal.
  ///
  /// `NWEndpoint.Host`'s description carries the interface on a link-local
  /// address — `fe80::1%en0` — and that suffix is not part of the address. It
  /// would survive into a URL and make every request to it fail to parse.
  private static func describe(_ host: NWEndpoint.Host) -> String {
    let text: String
    switch host {
    case .ipv4(let address):
      text = "\(address)"
    case .ipv6(let address):
      text = "\(address)"
    case .name(let name, _):
      text = name
    @unknown default:
      text = "\(host)"
    }
    guard let zone = text.firstIndex(of: "%") else { return text }
    return String(text[text.startIndex..<zone])
  }
}
