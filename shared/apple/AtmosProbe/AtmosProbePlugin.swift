import AVFoundation
import Flutter
import Foundation

/// Diagnostics harness for #1300: plays known assets through a bare AVPlayer
/// so a tester can read the receiver's format display per test.
///
/// Modes:
///  - hlsAtmos:    Apple's public fMP4 Atmos example stream (device+AVR+MAT baseline)
///  - hlsControl:  Apple's public EC3 5.1 (non-JOC) example stream (control)
///  - rawEc3:      raw .ec3 elementary stream via AVAssetResourceLoader with an
///                 unbounded content length — a faithful rehearsal of the mpv
///                 AVPlayer audio sink's feeding model
///  - rawEc3Finite: same loader but passing through the real content length,
///                 isolating "loader trick" failures from "raw ES" failures
public class AtmosProbePlugin: NSObject, FlutterPlugin {
  private static let hlsAtmosUrl =
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"
  private static let hlsControlUrl =
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"

  private var player: AVPlayer?
  private var loader: RawEc3Loader?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "plezy/atmos_probe", binaryMessenger: registrar.messenger())
    let instance = AtmosProbePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "start":
      guard let args = call.arguments as? [String: Any],
        let mode = args["mode"] as? String
      else {
        result(FlutterError(code: "bad_args", message: "mode required", details: nil))
        return
      }
      start(mode: mode, url: args["url"] as? String, result: result)
    case "stop":
      stopPlayback()
      result(nil)
    case "getStatus":
      result(status())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(mode: String, url: String?, result: @escaping FlutterResult) {
    stopPlayback()

    let item: AVPlayerItem
    switch mode {
    case "hlsAtmos", "hlsControl":
      let raw = mode == "hlsAtmos" ? Self.hlsAtmosUrl : Self.hlsControlUrl
      guard let streamUrl = URL(string: raw) else {
        result(FlutterError(code: "bad_url", message: raw, details: nil))
        return
      }
      item = AVPlayerItem(url: streamUrl)
    case "rawEc3", "rawEc3Finite":
      guard let source = url.flatMap(URL.init(string:)) else {
        result(FlutterError(code: "bad_url", message: "rawEc3 needs a source url", details: nil))
        return
      }
      let loader = RawEc3Loader(source: source, finiteLength: mode == "rawEc3Finite")
      self.loader = loader
      item = AVPlayerItem(asset: loader.asset)
      item.preferredForwardBufferDuration = 1.0
      loader.begin()
    default:
      result(FlutterError(code: "bad_mode", message: mode, details: nil))
      return
    }

    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = false
    player.allowsExternalPlayback = false
    self.player = player
    player.play()
    result(nil)
  }

  private func stopPlayback() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    loader?.cancel()
    loader = nil
  }

  private func status() -> [String: Any] {
    var out: [String: Any] = [:]

    let session = AVAudioSession.sharedInstance()
    out["maxOutputChannels"] = session.maximumOutputNumberOfChannels
    out["outputLatencyMs"] = Int(session.outputLatency * 1000)
    out["route"] = session.currentRoute.outputs.map { port in
      "\(port.portType.rawValue)/\(port.portName)/\(port.channels?.count ?? 0)ch"
    }.joined(separator: ", ")
    if #available(iOS 17.2, tvOS 17.2, *) {
      out["renderingMode"] = String(describing: session.renderingMode)
      out["renderingModeRawValue"] = session.renderingMode.rawValue
    }

    guard let player = player else {
      out["state"] = "idle"
      return out
    }

    let item = player.currentItem
    out["state"] =
      switch player.timeControlStatus {
      case .paused: "paused"
      case .waitingToPlayAtSpecifiedRate:
        "waiting(\(player.reasonForWaitingToPlay?.rawValue ?? "-"))"
      case .playing: "playing"
      @unknown default: "unknown"
      }
    out["itemStatus"] =
      switch item?.status {
      case .readyToPlay: "readyToPlay"
      case .failed: "failed"
      default: "unknown"
      }
    if let error = item?.error as NSError? {
      out["error"] = "\(error.domain):\(error.code) \(error.localizedDescription)"
    }
    if let item = item {
      out["currentTime"] = CMTimeGetSeconds(item.currentTime())
      out["tracks"] = item.tracks.compactMap { track -> String? in
        guard let assetTrack = track.assetTrack else { return nil }
        let formats = (assetTrack.formatDescriptions as! [CMFormatDescription]).map { desc in
          fourCC(CMFormatDescriptionGetMediaSubType(desc))
        }.joined(separator: "+")
        return "\(assetTrack.mediaType.rawValue):\(formats)"
      }.joined(separator: ", ")
    }
    if let loader = loader {
      out["fedBytes"] = loader.bytesReceived
      out["loaderRequests"] = loader.requestLog
    }
    return out
  }

  private func fourCC(_ code: FourCharCode) -> String {
    let bytes = [
      UInt8((code >> 24) & 0xFF), UInt8((code >> 16) & 0xFF),
      UInt8((code >> 8) & 0xFF), UInt8(code & 0xFF),
    ]
    return String(bytes: bytes, encoding: .ascii) ?? String(code)
  }
}

/// Streams an HTTP source into memory and serves it to AVPlayer through an
/// AVAssetResourceLoader on a custom scheme, mirroring the mpv sink's model.
private final class RawEc3Loader: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate {
  let asset: AVURLAsset
  private let source: URL
  private let finiteLength: Bool
  private let queue = DispatchQueue(label: "plezy.atmos.probe.loader")
  private var session: URLSession!
  private var buffer = Data()
  private var contentLength: Int64 = -1
  private var finished = false
  private var pending: [AVAssetResourceLoadingRequest] = []
  private(set) var bytesReceived: Int = 0
  private(set) var requestLog: String = ""

  init(source: URL, finiteLength: Bool) {
    self.source = source
    self.finiteLength = finiteLength
    self.asset = AVURLAsset(url: URL(string: "plezy-ec3-probe://stream/audio.ec3")!)
    super.init()
    asset.resourceLoader.setDelegate(self, queue: queue)
  }

  func begin() {
    let config = URLSessionConfiguration.default
    session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    session.dataTask(with: source).resume()
  }

  func cancel() {
    session?.invalidateAndCancel()
    queue.async {
      for request in self.pending where !request.isFinished {
        request.finishLoading(with: NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled))
      }
      self.pending.removeAll()
    }
  }

  // MARK: URLSessionDataDelegate (background queue -> hop to `queue`)

  func urlSession(
    _ session: URLSession, dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    queue.async {
      self.contentLength = response.expectedContentLength
      self.serve()
    }
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    queue.async {
      self.buffer.append(data)
      self.bytesReceived += data.count
      self.serve()
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    queue.async {
      self.finished = true
      self.serve()
    }
  }

  // MARK: AVAssetResourceLoaderDelegate (on `queue`)

  func resourceLoader(
    _ resourceLoader: AVAssetResourceLoader,
    shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
  ) -> Bool {
    if let dataRequest = loadingRequest.dataRequest {
      requestLog += "[\(dataRequest.requestedOffset)+\(dataRequest.requestedLength)]"
      if requestLog.count > 300 { requestLog = String(requestLog.suffix(300)) }
    }
    pending.append(loadingRequest)
    serve()
    return true
  }

  func resourceLoader(
    _ resourceLoader: AVAssetResourceLoader,
    didCancel loadingRequest: AVAssetResourceLoadingRequest
  ) {
    pending.removeAll { $0 === loadingRequest }
  }

  private func serve() {
    // content info: unbounded mirrors the mpv sink; finite passes the real
    // length through once the HTTP response reveals it
    let knownLength: Int64? =
      finiteLength
      ? (contentLength >= 0 ? contentLength : (finished ? Int64(buffer.count) : nil))
      : Int64(1) << 40

    var index = 0
    while index < pending.count {
      let request = pending[index]
      if let info = request.contentInformationRequest {
        guard let length = knownLength else {
          index += 1
          continue  // wait for the HTTP response before answering
        }
        info.contentType = "public.enhanced-ac3-audio"
        info.contentLength = length
        info.isByteRangeAccessSupported = true
        if request.dataRequest == nil {
          request.finishLoading()
          pending.remove(at: index)
          continue
        }
      }
      guard let dataRequest = request.dataRequest else {
        index += 1
        continue
      }
      let offset = dataRequest.currentOffset
      let end = dataRequest.requestedOffset + Int64(dataRequest.requestedLength)
      if offset < Int64(buffer.count) {
        let chunkEnd = min(Int64(buffer.count), end)
        dataRequest.respond(with: buffer.subdata(in: Int(offset)..<Int(chunkEnd)))
      }
      if dataRequest.currentOffset >= end || (finished && dataRequest.currentOffset >= Int64(buffer.count)) {
        request.finishLoading()
        pending.remove(at: index)
        continue
      }
      index += 1
    }
  }
}
