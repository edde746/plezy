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
      let snapshot = loader.statusSnapshot()
      out["fedBytes"] = snapshot.bytesReceived
      out["loaderRequests"] = snapshot.requestLog
      out["loaderRetainedBytes"] = snapshot.retainedBytes
      out["loaderPendingRequests"] = snapshot.pendingRequestCount
      out["loaderMaximumBytes"] = snapshot.maximumBufferedBytes
      if let errorCode = snapshot.errorCode {
        out["loaderError"] = errorCode
      }
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
final class RawEc3Loader: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate {
  static let defaultMaximumBufferedBytes = 64 * 1_024 * 1_024
  private static let maximumPendingRequests = 256

  struct StatusSnapshot {
    let bytesReceived: Int
    let requestLog: String
    let retainedBytes: Int
    let pendingRequestCount: Int
    let maximumBufferedBytes: Int
    let errorCode: String?
    let isFinished: Bool
  }

  private enum State {
    case active
    case finished
    case failed(code: String, error: Error)
    case cancelled

    var terminalError: Error? {
      switch self {
      case .failed(_, let error):
        return error
      case .cancelled:
        return URLError(.cancelled)
      case .active, .finished:
        return nil
      }
    }

    var errorCode: String? {
      if case .failed(let code, _) = self { return code }
      return nil
    }

    var isFinished: Bool {
      if case .finished = self { return true }
      return false
    }
  }

  let asset: AVURLAsset
  let maximumBufferedBytes: Int
  private let source: URL
  private let finiteLength: Bool
  private let sessionConfiguration: URLSessionConfiguration
  private let queue = DispatchQueue(label: "plezy.atmos.probe.loader")
  private var terminalHandlerForTesting: (() -> Void)?
  private let queueKey = DispatchSpecificKey<Void>()
  private var session: URLSession?
  private var buffer = Data()
  private var contentLength: Int64 = -1
  private var state: State = .active
  private var pending: [AVAssetResourceLoadingRequest] = []
  private var bytesReceived = 0
  private var requestLog = ""
  private var hasBegun = false

  init(
    source: URL,
    finiteLength: Bool,
    maximumBufferedBytes: Int = RawEc3Loader.defaultMaximumBufferedBytes,
    sessionConfiguration: URLSessionConfiguration = .default,
    terminalHandlerForTesting: (() -> Void)? = nil
  ) {
    precondition(maximumBufferedBytes > 0)
    self.source = source
    self.finiteLength = finiteLength
    self.maximumBufferedBytes = maximumBufferedBytes
    self.sessionConfiguration = sessionConfiguration
    self.terminalHandlerForTesting = terminalHandlerForTesting
    self.asset = AVURLAsset(url: URL(string: "plezy-ec3-probe://stream/audio.ec3")!)
    super.init()
    queue.setSpecific(key: queueKey, value: ())
    asset.resourceLoader.setDelegate(self, queue: queue)
  }

  func begin() {
    queue.async { [weak self] in
      guard let self, !self.hasBegun else { return }
      guard case .active = self.state else { return }
      self.hasBegun = true
      let session = URLSession(
        configuration: self.sessionConfiguration,
        delegate: self,
        delegateQueue: nil
      )
      self.session = session
      session.dataTask(with: self.source).resume()
    }
  }

  func cancel() {
    queue.async { [weak self] in
      self?.cancelOnQueue()
    }
  }

  /// Called only from the method-channel/main path, never from the loader queue.
  func statusSnapshot() -> StatusSnapshot {
    syncOnQueue {
      StatusSnapshot(
        bytesReceived: bytesReceived,
        requestLog: requestLog,
        retainedBytes: buffer.count,
        pendingRequestCount: pending.count,
        maximumBufferedBytes: maximumBufferedBytes,
        errorCode: state.errorCode,
        isFinished: state.isFinished
      )
    }
  }

  private func syncOnQueue<T>(_ body: () -> T) -> T {
    if DispatchQueue.getSpecific(key: queueKey) != nil {
      return body()
    }
    return queue.sync(execute: body)
  }

  private func notifyTerminalForTesting() {
    let handler = terminalHandlerForTesting
    terminalHandlerForTesting = nil
    handler?()
  }

  private func cancelOnQueue() {
    guard case .active = state else {
      if case .finished = state {
        state = .cancelled
        finishPending(with: URLError(.cancelled))
        releaseRetainedBytes()
      }
      return
    }
    state = .cancelled
    session?.invalidateAndCancel()
    session = nil
    finishPending(with: URLError(.cancelled))
    releaseRetainedBytes()
    notifyTerminalForTesting()
  }

  private func failOnQueue(code: String, error: Error) {
    guard case .active = state else { return }
    state = .failed(code: code, error: error)
    session?.invalidateAndCancel()
    session = nil
    finishPending(with: error)
    releaseRetainedBytes()
    notifyTerminalForTesting()
  }

  private func finishPending(with error: Error) {
    let requests = pending
    pending.removeAll(keepingCapacity: false)
    for request in requests where !request.isFinished {
      request.finishLoading(with: error)
    }
  }

  private func releaseRetainedBytes() {
    buffer.removeAll(keepingCapacity: false)
  }

  // MARK: URLSessionDataDelegate (background queue -> hop to `queue`)

  func urlSession(
    _ session: URLSession,
    dataTask: URLSessionDataTask,
    didReceive response: URLResponse,
    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
  ) {
    queue.async { [weak self] in
      guard let self, case .active = self.state else { return }
      self.contentLength = response.expectedContentLength
      if response.expectedContentLength > Int64(self.maximumBufferedBytes) {
        self.failOnQueue(
          code: "response_too_large",
          error: URLError(.dataLengthExceedsMaximum)
        )
      } else {
        self.serve()
      }
    }
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    queue.async { [weak self] in
      guard let self, case .active = self.state else { return }
      guard data.count <= self.maximumBufferedBytes - self.buffer.count else {
        self.failOnQueue(
          code: "response_too_large",
          error: URLError(.dataLengthExceedsMaximum)
        )
        return
      }
      self.buffer.append(data)
      self.bytesReceived += data.count
      self.serve()
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    queue.async { [weak self] in
      guard let self, case .active = self.state else { return }
      self.session = nil
      if let error {
        self.state = .failed(code: "network_error", error: error)
        self.finishPending(with: error)
        self.releaseRetainedBytes()
      } else {
        self.state = .finished
        self.serve()
      }
      self.notifyTerminalForTesting()
      session.finishTasksAndInvalidate()
    }
  }

  // MARK: AVAssetResourceLoaderDelegate (on `queue`)

  func resourceLoader(
    _ resourceLoader: AVAssetResourceLoader,
    shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
  ) -> Bool {
    if let terminalError = state.terminalError {
      loadingRequest.finishLoading(with: terminalError)
      return true
    }
    guard pending.count < Self.maximumPendingRequests else {
      loadingRequest.finishLoading(with: URLError(.resourceUnavailable))
      return true
    }
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
    let isFinished: Bool
    switch state {
    case .active:
      isFinished = false
    case .finished:
      isFinished = true
    case .failed, .cancelled:
      return
    }

    // The logical 1-TiB length remains the raw probe contract. Retained bytes
    // are independently bounded by maximumBufferedBytes.
    let knownLength: Int64? =
      finiteLength
      ? (contentLength >= 0 ? contentLength : (isFinished ? Int64(buffer.count) : nil))
      : Int64(1) << 40

    var index = 0
    while index < pending.count {
      let request = pending[index]
      if let info = request.contentInformationRequest {
        guard let length = knownLength else {
          index += 1
          continue
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

      let requestedOffset = dataRequest.requestedOffset
      let currentOffset = dataRequest.currentOffset
      let requestedLength = Int64(dataRequest.requestedLength)
      let (end, overflow) = requestedOffset.addingReportingOverflow(requestedLength)
      guard requestedOffset >= 0, currentOffset >= requestedOffset, requestedLength >= 0, !overflow else {
        request.finishLoading(with: URLError(.badServerResponse))
        pending.remove(at: index)
        continue
      }

      let bufferedCount = Int64(buffer.count)
      if currentOffset < bufferedCount {
        let chunkEnd = min(bufferedCount, end)
        guard currentOffset <= chunkEnd,
          let start = Int(exactly: currentOffset),
          let finish = Int(exactly: chunkEnd)
        else {
          request.finishLoading(with: URLError(.badServerResponse))
          pending.remove(at: index)
          continue
        }
        dataRequest.respond(with: buffer.subdata(in: start..<finish))
      }
      if dataRequest.currentOffset >= end
        || (isFinished && dataRequest.currentOffset >= bufferedCount)
      {
        request.finishLoading()
        pending.remove(at: index)
        continue
      }
      index += 1
    }
  }
}
