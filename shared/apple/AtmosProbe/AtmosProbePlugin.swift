import AVFoundation
import Flutter
import Foundation
#if os(iOS) || os(tvOS)
  import AVKit
  import UIKit
#endif

/// Diagnostics harness for #1300: plays known assets through a bare AVPlayer
/// or through a bare AVSampleBufferAudioRenderer so a tester can read the
/// receiver's format display per test.
///
/// Modes:
///  - hlsAtmos:    Apple's public fMP4 Atmos example stream (device+AVR+MAT baseline)
///  - hlsControl:  Apple's public EC3 5.1 (non-JOC) example stream (control)
///  - rawEc3:      raw .ec3 elementary stream via AVAssetResourceLoader with an
///                 unbounded content length — a faithful rehearsal of the mpv
///                 AVPlayer audio sink's feeding model
///  - rawEc3Finite: same loader but passing through the real content length,
///                 isolating "loader trick" failures from "raw ES" failures
///  - asbarNative: the decisive arm. Reads the asset with AVAssetReader at
///                 `outputSettings: nil` and hands the resulting *native*
///                 compressed CMSampleBuffers and *native* CMFormatDescription
///                 straight to AVSampleBufferAudioRenderer, following Apple's
///                 flexible enhanced buffering sequence. No mpv, no FFmpeg
///                 spdif muxer, no generated ASBD, no hand-built dec3. If this
///                 reaches Atmos, the production sink has a construction bug;
///                 if it does not, AVSampleBufferAudioRenderer cannot carry
///                 JOC on this route and the architecture must change.
///  - asbarGenerated: same feed, but the format description is rebuilt the way
///                 the mpv AO builds it (generated ASBD + dec3 magic cookie +
///                 MPEG_5_1_C layout). A/B against asbarNative isolates
///                 descriptor construction from everything else.
public class AtmosProbePlugin: NSObject, FlutterPlugin {
  private static let hlsAtmosUrl =
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/adv_dv_atmos/main.m3u8"
  private static let hlsControlUrl =
    "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_adv_example_hevc/master.m3u8"

  private var player: AVPlayer?
  private var loader: RawEc3Loader?
  private var asbar: AsbarProbe?
  #if os(iOS) || os(tvOS)
    private var routePicker: AVRoutePickerView?
  #endif

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
      start(
        mode: mode, url: args["url"] as? String,
        sessionMode: args["sessionMode"] as? String, result: result)
    case "stop":
      stopPlayback()
      result(nil)
    case "showRoutePicker":
      result(setRoutePickerVisible(true))
    case "hideRoutePicker":
      result(setRoutePickerVisible(false))
    case "getStatus":
      result(status())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func start(
    mode: String, url: String?, sessionMode: String?,
    result: @escaping FlutterResult
  ) {
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
    case "asbarNative", "asbarGenerated":
      guard let source = url.flatMap(URL.init(string:)) else {
        result(
          FlutterError(code: "bad_url", message: "\(mode) needs a source url", details: nil))
        return
      }
      let probe = AsbarProbe(
        source: source,
        regenerateFormatDescription: mode == "asbarGenerated",
        // Dolby's Figure 1 prescribes mode .default; .moviePlayback is what
        // the shipping AO used. Selectable so the tester can A/B it.
        sessionMode: sessionMode == "moviePlayback" ? .moviePlayback : .default)
      asbar = probe
      probe.start { error in
        if let error {
          result(FlutterError(code: "asbar_failed", message: error, details: nil))
        } else {
          result(nil)
        }
      }
      return
    default:
      result(FlutterError(code: "bad_mode", message: mode, details: nil))
      return
    }

    let player = AVPlayer(playerItem: item)
    player.automaticallyWaitsToMinimizeStalling = false
    // Must stay true: the route picker exists so these arms can be compared
    // against the sample-buffer arms on an AirPlay destination, and AirPlay is
    // the only route where the system resolves renderingMode and
    // supportedOutputChannelLayouts. Pinning playback local would leave the
    // AVPlayer controls on HDMI while the picker moved everything else.
    player.allowsExternalPlayback = true
    self.player = player
    player.play()
    result(nil)
  }

  /// Dolby's flow opens with an AVRoutePickerView so the tester can move
  /// playback to an AirPlay destination. That matters here beyond conformance:
  /// AVRoutePickerView.h states media from an AVSampleBufferAudioRenderer can
  /// be routed to AirPlay on tvOS, and AirPlay is the only route where
  /// `renderingMode` and `supportedOutputChannelLayouts` actually resolve — so
  /// this is what makes the AirPlay arm of the test matrix reachable from the
  /// device.
  private func setRoutePickerVisible(_ visible: Bool) -> Bool {
    #if os(iOS) || os(tvOS)
      guard visible else {
        routePicker?.removeFromSuperview()
        routePicker = nil
        return true
      }
      if routePicker != nil { return true }
      guard let window = Self.keyWindow() else { return false }
      let picker = AVRoutePickerView()
      picker.translatesAutoresizingMaskIntoConstraints = false
      window.addSubview(picker)
      NSLayoutConstraint.activate([
        picker.centerXAnchor.constraint(equalTo: window.centerXAnchor),
        picker.bottomAnchor.constraint(equalTo: window.centerYAnchor, constant: -40),
        picker.widthAnchor.constraint(equalToConstant: 120),
        picker.heightAnchor.constraint(equalToConstant: 80),
      ])
      routePicker = picker
      window.setNeedsFocusUpdate()
      window.updateFocusIfNeeded()
      return true
    #else
      return false
    #endif
  }

  #if os(iOS) || os(tvOS)
    private static func keyWindow() -> UIWindow? {
      UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first { $0.isKeyWindow }
        ?? UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap(\.windows)
        .first
    }
  #endif

  private func stopPlayback() {
    player?.pause()
    player?.replaceCurrentItem(with: nil)
    player = nil
    loader?.cancel()
    loader = nil
    asbar?.cancel()
    asbar = nil
    _ = setRoutePickerVisible(false)
    // Run isolation: never let a failed compressed route leak into the next
    // variant or into other apps.
    try? AVAudioSession.sharedInstance().setActive(
      false, options: .notifyOthersOnDeactivation)
  }

  private func status() -> [String: Any] {
    var out: [String: Any] = [:]

    let session = AVAudioSession.sharedInstance()
    out["maxOutputChannels"] = session.maximumOutputNumberOfChannels
    out["outputLatencyMs"] = Int(session.outputLatency * 1000)
    out["route"] = session.currentRoute.outputs.map { port in
      "\(port.portType.rawValue)/\(port.portName)/\(port.channels?.count ?? 0)ch"
    }.joined(separator: ", ")
    out["sessionCategory"] = session.category.rawValue
    out["sessionMode"] = session.mode.rawValue
    out["routeSharingPolicy"] = session.routeSharingPolicy.rawValue
    out["categoryOptions"] = session.categoryOptions.rawValue
    if #available(iOS 17.2, tvOS 17.2, *) {
      out["renderingMode"] = String(describing: session.renderingMode)
      out["renderingModeRawValue"] = session.renderingMode.rawValue
      // Empty on HDMI by design (CarPlay/AirPlay only). Reported so a tester
      // can tell "empty because HDMI" from "empty because inactive".
      out["supportedOutputChannelLayouts"] = session.supportedOutputChannelLayouts.map {
        String(format: "0x%08x/%uch", $0.layoutTag, $0.channelCount)
      }.joined(separator: ", ")
    }

    if let asbar {
      out.merge(asbar.statusSnapshot()) { _, new in new }
      return out
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

/// Feeds compressed E-AC-3 access units to a bare `AVSampleBufferAudioRenderer`
/// using Apple's flexible enhanced buffering sequence.
///
/// This is deliberately the shortest possible path from file bytes to the
/// system decoder: `AVAssetReader` at `outputSettings: nil` yields the native
/// compressed sample buffers and the native `CMFormatDescription` that
/// AVFoundation itself would use. Nothing else touches the data, so a failure
/// here is a property of the renderer, not of our packetization.
final class AsbarProbe: NSObject {
  private static var statusContext = 0

  private let source: URL
  private let regenerateFormatDescription: Bool
  private let sessionMode: AVAudioSession.Mode
  private let queue = DispatchQueue(
    label: "plezy.atmos.probe.asbar", qos: .userInitiated)
  private let lock = NSLock()

  private var renderer: AVSampleBufferAudioRenderer?
  private var synchronizer: AVSampleBufferRenderSynchronizer?
  private var reader: AVAssetReader?
  private var output: AVAssetReaderTrackOutput?
  private var temporaryFile: URL?
  private var download: URLSessionDownloadTask?
  private var statusObserved = false
  private var cancelled = false
  // Guarded by `lock`. Consumed exactly once — by the start path that reaches a
  // verdict, by `cancel()`, or by `deinit`, whichever happens first.
  private var startCompletion: ((String?) -> Void)?

  // Guarded by `lock`; read from the method-channel thread.
  private var enqueuedSamples = 0
  private var nativeDescription = "unknown"
  private var usedDescription = "unknown"
  private var magicCookieHex = "none"
  private var layoutTagText = "none"
  private var phase = "starting"
  private var failure: String?

  init(
    source: URL, regenerateFormatDescription: Bool, sessionMode: AVAudioSession.Mode
  ) {
    self.source = source
    self.regenerateFormatDescription = regenerateFormatDescription
    self.sessionMode = sessionMode
    super.init()
  }

  /// `completion` reports only whether the run could be started.
  func start(completion: @escaping (String?) -> Void) {
    lock.lock()
    startCompletion = completion
    let aborted = cancelled
    lock.unlock()
    if aborted {
      finishStart("cancelled")
      return
    }

    if source.isFileURL {
      queue.async { [weak self] in
        guard let self else { return }
        self.finishStart(self.beginReading(from: self.source))
      }
      return
    }

    // AVAssetReader needs a seekable local asset; stage the source first.
    setPhase("downloading")
    let task = URLSession.shared.downloadTask(with: source) { [weak self] url, _, error in
      guard let self else { return }  // covered by `deinit`
      guard let url else {
        let message = error?.localizedDescription ?? "download failed"
        self.fail(message)
        self.finishStart(message)
        return
      }
      // The temporary file is removed as soon as this handler returns.
      let staged = FileManager.default.temporaryDirectory
        .appendingPathComponent("plezy-asbar-\(UUID().uuidString)")
        .appendingPathExtension(self.source.pathExtension.isEmpty ? "eac3" : self.source.pathExtension)
      do {
        try FileManager.default.moveItem(at: url, to: staged)
      } catch {
        let message = "failed to stage asset: \(error.localizedDescription)"
        self.fail(message)
        self.finishStart(message)
        return
      }
      self.lock.lock()
      self.temporaryFile = staged
      let aborted = self.cancelled
      self.lock.unlock()
      if aborted {
        try? FileManager.default.removeItem(at: staged)
        self.finishStart("cancelled")  // no-op if `cancel()` already fired
        return
      }
      self.queue.async {
        self.finishStart(self.beginReading(from: staged))
      }
    }
    lock.lock()
    download = task
    lock.unlock()
    task.resume()
  }

  func cancel() {
    lock.lock()
    cancelled = true
    let task = download
    let staged = temporaryFile
    download = nil
    temporaryFile = nil
    lock.unlock()
    task?.cancel()
    finishStart("cancelled")

    queue.sync {
      if statusObserved, let renderer {
        renderer.removeObserver(
          self, forKeyPath: "status", context: &AsbarProbe.statusContext)
        statusObserved = false
      }
      renderer?.stopRequestingMediaData()
      renderer?.flush()
      synchronizer?.rate = 0
      if let renderer, let synchronizer {
        synchronizer.removeRenderer(renderer, at: .zero, completionHandler: nil)
      }
      reader?.cancelReading()
      reader = nil
      output = nil
      renderer = nil
      synchronizer = nil
    }
    if let staged { try? FileManager.default.removeItem(at: staged) }
    setPhase("cancelled")
  }

  deinit {
    // `stopPlayback()` drops the only strong reference (`asbar = nil`), so the
    // probe can die with a download still in flight; the handler's
    // `guard let self` would then swallow the verdict for good.
    finishStart("cancelled")
  }

  /// Runs on `queue`. Returns a message on failure.
  private func beginReading(from url: URL) -> String? {
    lock.lock()
    let aborted = cancelled
    lock.unlock()
    if aborted { return nil }

    let asset = AVURLAsset(url: url)
    guard let track = asset.tracks(withMediaType: .audio).first else {
      let message = "no audio track in \(url.lastPathComponent)"
      fail(message)
      return message
    }
    guard
      let nativeFormat = (track.formatDescriptions as? [CMFormatDescription])?.first
    else {
      let message = "audio track has no format description"
      fail(message)
      return message
    }
    describe(nativeFormat)

    let assetReader: AVAssetReader
    do {
      assetReader = try AVAssetReader(asset: asset)
    } catch {
      let message = "AVAssetReader init failed: \(error.localizedDescription)"
      fail(message)
      return message
    }
    // `nil` output settings is what keeps the samples compressed.
    let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
    trackOutput.alwaysCopiesSampleData = false
    guard assetReader.canAdd(trackOutput) else {
      let message = "AVAssetReader rejected a compressed output"
      fail(message)
      return message
    }
    assetReader.add(trackOutput)
    guard assetReader.startReading() else {
      let message =
        "AVAssetReader.startReading failed: \(assetReader.error?.localizedDescription ?? "unknown")"
      fail(message)
      return message
    }

    var substituteFormat: CMFormatDescription?
    if regenerateFormatDescription {
      let rebuilt = Self.regenerate(from: nativeFormat)
      guard let format = rebuilt.format else {
        let message = rebuilt.error ?? "format regeneration failed"
        fail(message)
        return message
      }
      substituteFormat = format
      describeUsed(format)
    } else {
      describeUsed(nativeFormat)
    }

    if let message = configureSession() { return message }

    let renderer = AVSampleBufferAudioRenderer()
    let synchronizer = AVSampleBufferRenderSynchronizer()
    synchronizer.addRenderer(renderer)
    // Deliberately NOT disabling delaysRateChangeUntilHasSufficientMediaData:
    // the reliable-start preroll is part of the sequence under test.
    renderer.addObserver(
      self, forKeyPath: "status", options: [.new], context: &AsbarProbe.statusContext)

    self.renderer = renderer
    self.synchronizer = synchronizer
    self.reader = assetReader
    self.output = trackOutput
    statusObserved = true

    setPhase("feeding")
    // Apple's order: request media first, start the clock after.
    renderer.requestMediaDataWhenReady(on: queue) { [weak self] in
      self?.pump(substituteFormat: substituteFormat)
    }
    synchronizer.rate = 1
    return nil
  }

  /// Runs on `queue`.
  private func pump(substituteFormat: CMFormatDescription?) {
    guard let renderer, let output, let reader else { return }
    while renderer.isReadyForMoreMediaData {
      guard reader.status == .reading, let sample = output.copyNextSampleBuffer() else {
        renderer.stopRequestingMediaData()
        setPhase(reader.status == .completed ? "finished" : "stopped(\(reader.status.rawValue))")
        return
      }
      let enqueued: CMSampleBuffer
      if let substituteFormat {
        guard let rewrapped = Self.rewrap(sample, with: substituteFormat) else {
          fail("failed to rewrap a sample with the generated description")
          renderer.stopRequestingMediaData()
          return
        }
        enqueued = rewrapped
      } else {
        enqueued = sample
      }
      renderer.enqueue(enqueued)
      lock.lock()
      enqueuedSamples += 1
      lock.unlock()
    }
  }

  private func configureSession() -> String? {
    #if os(iOS) || os(tvOS)
      let session = AVAudioSession.sharedInstance()
      do {
        try session.setCategory(
          .playback, mode: sessionMode, policy: .longFormAudio, options: [])
      } catch {
        let message = "long-form session profile rejected: \(error.localizedDescription)"
        fail(message)
        return message
      }
      if #available(iOS 15.0, tvOS 15.0, *) {
        try? session.setSupportsMultichannelContent(true)
      }
      do {
        try session.setActive(true)
      } catch {
        let message = "session activation failed: \(error.localizedDescription)"
        fail(message)
        return message
      }
    #endif
    return nil
  }

  override func observeValue(
    forKeyPath keyPath: String?, of object: Any?,
    change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?
  ) {
    guard context == &AsbarProbe.statusContext else {
      super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
      return
    }
    guard let renderer = object as? AVSampleBufferAudioRenderer,
      renderer.status == .failed
    else { return }
    let error = renderer.error as NSError?
    fail(
      "renderer failed: \(error?.domain ?? "-"):\(error?.code ?? 0) "
        + (error?.localizedDescription ?? "unknown"))
  }

  func statusSnapshot() -> [String: Any] {
    lock.lock()
    defer { lock.unlock() }
    var out: [String: Any] = [
      "state": phase,
      "asbarEnqueuedSamples": enqueuedSamples,
      "asbarNativeFormat": nativeDescription,
      "asbarUsedFormat": usedDescription,
      "asbarMagicCookie": magicCookieHex,
      "asbarChannelLayout": layoutTagText,
    ]
    if let failure { out["error"] = failure }
    if let renderer {
      out["asbarRendererStatus"] =
        switch renderer.status {
        case .unknown: "unknown"
        case .rendering: "rendering"
        case .failed: "failed"
        @unknown default: "unrecognized"
        }
    }
    if let synchronizer {
      out["currentTime"] = CMTimeGetSeconds(synchronizer.currentTime())
    }
    return out
  }

  // MARK: - Format description helpers

  private func describe(_ format: CMFormatDescription) {
    let text = Self.summarize(format)
    lock.lock()
    nativeDescription = text.summary
    magicCookieHex = text.cookie
    layoutTagText = text.layout
    lock.unlock()
  }

  private func describeUsed(_ format: CMFormatDescription) {
    let text = Self.summarize(format)
    lock.lock()
    usedDescription = text.summary
    lock.unlock()
  }

  private static func summarize(
    _ format: CMFormatDescription
  ) -> (summary: String, cookie: String, layout: String) {
    var summary = "subType=\(fourCCText(CMFormatDescriptionGetMediaSubType(format)))"
    if let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(format)?.pointee {
      summary +=
        String(
          format: " rate=%.0f ch=%u framesPerPacket=%u", asbd.mSampleRate,
          asbd.mChannelsPerFrame, asbd.mFramesPerPacket)
    }
    var cookieSize = 0
    var cookie = "none"
    if let bytes = CMAudioFormatDescriptionGetMagicCookie(format, sizeOut: &cookieSize),
      cookieSize > 0
    {
      cookie = Data(bytes: bytes, count: cookieSize).map { String(format: "%02x", $0) }
        .joined()
    }
    var layoutSize = 0
    var layout = "none"
    if let acl = CMAudioFormatDescriptionGetChannelLayout(format, sizeOut: &layoutSize) {
      layout = String(format: "0x%08x", acl.pointee.mChannelLayoutTag)
    }
    return (summary, cookie, layout)
  }

  private static func fourCCText(_ code: FourCharCode) -> String {
    let bytes = [
      UInt8((code >> 24) & 0xFF), UInt8((code >> 16) & 0xFF),
      UInt8((code >> 8) & 0xFF), UInt8(code & 0xFF),
    ]
    return String(bytes: bytes, encoding: .ascii) ?? String(code)
  }

  /// Rebuild the description the way the mpv AO does: same ASBD and magic
  /// cookie, but constructed by us rather than parsed out of the container,
  /// with the Dolby-order 5.1 layout attached.
  private static func regenerate(
    from native: CMFormatDescription
  ) -> (format: CMFormatDescription?, error: String?) {
    guard var asbd = CMAudioFormatDescriptionGetStreamBasicDescription(native)?.pointee else {
      return (nil, "native description has no ASBD")
    }
    var cookieSize = 0
    var cookieBytes: [UInt8] = []
    if let bytes = CMAudioFormatDescriptionGetMagicCookie(native, sizeOut: &cookieSize),
      cookieSize > 0
    {
      cookieBytes = Array(UnsafeRawBufferPointer(start: bytes, count: cookieSize))
    }
    var layout = AudioChannelLayout()
    layout.mChannelLayoutTag =
      asbd.mChannelsPerFrame == 8
      ? kAudioChannelLayoutTag_MPEG_7_1_C : kAudioChannelLayoutTag_MPEG_5_1_C

    var rebuilt: CMFormatDescription?
    let status = cookieBytes.withUnsafeBytes { cookie -> OSStatus in
      CMAudioFormatDescriptionCreate(
        allocator: kCFAllocatorDefault,
        asbd: &asbd,
        layoutSize: MemoryLayout<AudioChannelLayout>.size,
        layout: &layout,
        magicCookieSize: cookie.count,
        magicCookie: cookie.baseAddress,
        extensions: nil,
        formatDescriptionOut: &rebuilt)
    }
    guard status == noErr, let rebuilt else {
      return (nil, "CMAudioFormatDescriptionCreate failed (\(status))")
    }
    return (rebuilt, nil)
  }

  private static func rewrap(
    _ sample: CMSampleBuffer, with format: CMFormatDescription
  ) -> CMSampleBuffer? {
    guard let blockBuffer = CMSampleBufferGetDataBuffer(sample) else { return nil }
    var timing = CMSampleTimingInfo()
    guard CMSampleBufferGetSampleTimingInfo(sample, at: 0, timingInfoOut: &timing) == noErr
    else { return nil }
    var sizeOut = 0
    let sizeStatus = CMSampleBufferGetSampleSizeArray(
      sample, entryCount: 0, arrayToFill: nil, entriesNeededOut: &sizeOut)
    var sizes = [Int](repeating: 0, count: max(sizeOut, 1))
    if sizeStatus == noErr, sizeOut > 0 {
      _ = CMSampleBufferGetSampleSizeArray(
        sample, entryCount: sizeOut, arrayToFill: &sizes, entriesNeededOut: nil)
    } else {
      sizes[0] = CMBlockBufferGetDataLength(blockBuffer)
    }
    var rewrapped: CMSampleBuffer?
    let status = CMSampleBufferCreateReady(
      allocator: kCFAllocatorDefault,
      dataBuffer: blockBuffer,
      formatDescription: format,
      sampleCount: CMSampleBufferGetNumSamples(sample),
      sampleTimingEntryCount: 1,
      sampleTimingArray: &timing,
      sampleSizeEntryCount: sizes.count,
      sampleSizeArray: &sizes,
      sampleBufferOut: &rewrapped)
    return status == noErr ? rewrapped : nil
  }

  // MARK: - State

  /// Delivers the start verdict at most once, always on the main queue.
  /// Never call while holding `lock` (NSLock is not recursive).
  private func finishStart(_ message: String?) {
    lock.lock()
    let completion = startCompletion
    startCompletion = nil
    lock.unlock()
    guard let completion else { return }
    // Captures only `completion` and `message` — never `self`, so this is safe
    // to call from `deinit`.
    DispatchQueue.main.async { completion(message) }
  }

  private func setPhase(_ value: String) {
    lock.lock()
    phase = value
    lock.unlock()
  }

  private func fail(_ message: String) {
    lock.lock()
    if failure == nil { failure = message }
    phase = "failed"
    lock.unlock()
  }
}
