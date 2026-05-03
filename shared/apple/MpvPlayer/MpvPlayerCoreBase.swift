import Foundation
import Libmpv
import QuartzCore

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(macOS)
  import Cocoa
#endif

protocol MpvPlayerDelegate: AnyObject {
  func onPropertyChange(name: String, value: Any?)
  func onEvent(name: String, data: [String: Any]?)
}

// Workaround for MoltenVK problems that cause flicker.
// https://github.com/mpv-player/mpv/pull/13651
class MpvMetalLayer: CAMetalLayer {
  override var drawableSize: CGSize {
    get { super.drawableSize }
    set {
      if newValue == .zero || (Int(newValue.width) > 1 && Int(newValue.height) > 1) {
        super.drawableSize = newValue
      }
    }
  }

  #if os(iOS)
    // wantsExtendedDynamicRangeContent is unavailable on tvOS as of SDK 26.4,
    // so this override only applies to iOS / macOS.
    @available(iOS 16.0, *)
    override var wantsExtendedDynamicRangeContent: Bool {
      get { super.wantsExtendedDynamicRangeContent }
      set {
        if Thread.isMainThread {
          super.wantsExtendedDynamicRangeContent = newValue
        } else {
          DispatchQueue.main.sync {
            super.wantsExtendedDynamicRangeContent = newValue
          }
        }
      }
    }
  #elseif os(macOS)
    override var wantsExtendedDynamicRangeContent: Bool {
      get { super.wantsExtendedDynamicRangeContent }
      set {
        if Thread.isMainThread {
          super.wantsExtendedDynamicRangeContent = newValue
        } else {
          DispatchQueue.main.async {
            super.wantsExtendedDynamicRangeContent = newValue
          }
        }
      }
    }
  #endif
}

/// Safely convert a C string to Swift String with UTF-8 validation.
/// Falls back to Latin-1 decoding if the bytes are not valid UTF-8.
/// mpv does not guarantee UTF-8 for log messages, error strings, or
/// system-encoded paths and Flutter codecs reject invalid UTF-8.
func safeString(_ cstr: UnsafePointer<CChar>) -> String {
  if let string = String(validatingUTF8: cstr) {
    return string
  }

  let length = strlen(cstr)
  let buffer = UnsafeBufferPointer(
    start: UnsafeRawPointer(cstr).assumingMemoryBound(to: UInt8.self),
    count: length
  )
  return String(buffer.map { Character(Unicode.Scalar($0)) })
}

class MpvPlayerCoreBase: NSObject {
  weak var delegate: MpvPlayerDelegate?

  var metalLayer: MpvMetalLayer?
  var mpv: OpaquePointer?
  var isInitialized = false
  var isDisposing = false
  var isPipActive = false
  var isBackgrounded = false
  var hdrEnabled = true
  var lastSigPeak = 0.0

  /// Properties that must still flow to Dart while backgrounded (state-critical).
  private static let criticalProperties: Set<String> = [
    "pause", "eof-reached", "paused-for-cache",
  ]

  private static let internalSigPeakObserverId: UInt64 = UInt64.max - 1
  private static let internalWidthObserverId: UInt64 = UInt64.max - 2
  private static let internalHeightObserverId: UInt64 = UInt64.max - 3
  private static let internalObserverIds: Set<UInt64> = [
    internalSigPeakObserverId,
    internalWidthObserverId,
    internalHeightObserverId,
  ]

  let queue = DispatchQueue(label: "mpv", qos: .userInitiated)
  private let queueKey = DispatchSpecificKey<Void>()

  private enum PendingRequest {
    case void((Result<Void, Error>) -> Void)
    case getProperty((Result<String?, Error>) -> Void)
  }

  private var pendingRequests: [UInt64: PendingRequest] = [:]
  private let pendingRequestsLock = NSLock()
  private var nextRequestId: UInt64 = 1

  private let cacheLock = NSLock()
  private var cachedPaused = true
  private var cachedDuration = 0.0
  private var cachedTimePos = 0.0
  private var cachedWidth = 0.0
  private var cachedHeight = 0.0

  override init() {
    super.init()
    queue.setSpecific(key: queueKey, value: ())
  }

  func configurePlatformMpvOptions() {}

  func updateEDRMode(sigPeak: Double) {}

  func setupMpv() -> Bool {
    guard let metalLayer else { return false }

    mpv = mpv_create()
    guard let mpv else {
      print("[MpvPlayerCore] Failed to create MPV context")
      return false
    }

    #if DEBUG
      checkError(mpv_request_log_messages(mpv, "info"))
    #else
      checkError(mpv_request_log_messages(mpv, "warn"))
    #endif

    var layer = Int64(Int(bitPattern: Unmanaged.passUnretained(metalLayer).toOpaque()))
    checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &layer))
    applySharedMpvOptions()
    configurePlatformMpvOptions()

    let initResult = mpv_initialize(mpv)
    if initResult < 0 {
      print("[MpvPlayerCore] mpv_initialize failed: \(safeString(mpv_error_string(initResult)))")
      mpv_terminate_destroy(mpv)
      self.mpv = nil
      return false
    }

    mpv_set_wakeup_callback(
      mpv,
      { context in
        guard let context else { return }
        let core = Unmanaged<MpvPlayerCoreBase>.fromOpaque(context).takeUnretainedValue()
        core.readEvents()
      },
      UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    )

    mpv_observe_property(mpv, Self.internalSigPeakObserverId, "video-params/sig-peak", MPV_FORMAT_DOUBLE)
    mpv_observe_property(mpv, Self.internalWidthObserverId, "width", MPV_FORMAT_DOUBLE)
    mpv_observe_property(mpv, Self.internalHeightObserverId, "height", MPV_FORMAT_DOUBLE)
    return true
  }

  func setLogLevel(_ level: String) {
    guard let mpv else { return }
    mpv_request_log_messages(mpv, level)
  }

  func setProperty(_ name: String, value: String) {
    setPropertyAsync(name, value: value) { _ in }
  }

  func setPropertyAsync(
    _ name: String,
    value: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    if name == "pause" {
      setCachedPaused(value == "yes" || value == "true" || value == "1")
    }

    if name == "hdr-enabled" {
      let enabled = value == "yes" || value == "true" || value == "1"
      setHDREnabled(enabled, completion: completion)
      return
    }

    setRawStringPropertyAsync(name, value: value, completion: completion)
  }

  func setInt64PropertyAsync(
    _ name: String,
    value: Int64,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mpv else {
      completion(.success(()))
      return
    }

    let requestId = registerRequest(.void(completion))
    var propertyValue = value
    let status = name.withCString { namePointer in
      mpv_set_property_async(mpv, requestId, namePointer, MPV_FORMAT_INT64, &propertyValue)
    }
    completeRequestIfSubmissionFailed(requestId: requestId, status: status)
  }

  func setHDREnabled(_ enabled: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
    cacheLock.lock()
    hdrEnabled = enabled
    let sigPeak = lastSigPeak
    cacheLock.unlock()

    print("[MpvPlayerCore] HDR enabled: \(enabled)")

    setRawStringPropertyAsync(
      "target-colorspace-hint",
      value: enabled ? "yes" : "no",
      completion: completion ?? { _ in }
    )

    DispatchQueue.main.async {
      self.updateEDRMode(sigPeak: sigPeak)
    }
  }

  func getPropertyAsync(_ name: String, completion: @escaping (Result<String?, Error>) -> Void) {
    guard let mpv else {
      completion(.success(nil))
      return
    }

    let requestId = registerRequest(.getProperty(completion))
    let status = name.withCString { namePointer in
      mpv_get_property_async(mpv, requestId, namePointer, MPV_FORMAT_STRING)
    }
    completeRequestIfSubmissionFailed(requestId: requestId, status: status)
  }

  func observeProperty(_ name: String, format: String) {
    guard mpv != nil else { return }

    let mpvFormat: mpv_format
    switch format {
    case "double":
      mpvFormat = MPV_FORMAT_DOUBLE
    case "flag":
      mpvFormat = MPV_FORMAT_FLAG
    case "node":
      mpvFormat = MPV_FORMAT_NODE
    case "string":
      mpvFormat = MPV_FORMAT_STRING
    default:
      return
    }

    mpv_observe_property(mpv, 0, name, mpvFormat)
  }

  func command(_ args: [String]) {
    commandAsync(args) { _ in }
  }

  func commandAsync(_ args: [String], completion: @escaping (Result<Void, Error>) -> Void) {
    guard let mpv, !args.isEmpty else {
      completion(.success(()))
      return
    }

    let requestId = registerRequest(.void(completion))

    var cargs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
    cargs.append(nil)

    cargs.withUnsafeBufferPointer { buffer in
      var constPointers = buffer.map { UnsafePointer($0) }
      let result = mpv_command_async(mpv, requestId, &constPointers)
      completeRequestIfSubmissionFailed(requestId: requestId, status: result)
    }

    for pointer in cargs {
      free(pointer)
    }
  }

  private func setRawStringPropertyAsync(
    _ name: String,
    value: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard let mpv else {
      completion(.success(()))
      return
    }

    let requestId = registerRequest(.void(completion))
    let status = name.withCString { namePointer in
      value.withCString { valuePointer in
        var propertyValue: UnsafePointer<CChar>? = valuePointer
        return mpv_set_property_async(mpv, requestId, namePointer, MPV_FORMAT_STRING, &propertyValue)
      }
    }
    completeRequestIfSubmissionFailed(requestId: requestId, status: status)
  }

  var isPaused: Bool {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedPaused
  }

  var duration: Double {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedDuration
  }

  var timePos: Double {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedTimePos
  }

  var videoSize: CGSize? {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    guard cachedWidth > 0, cachedHeight > 0 else { return nil }
    return CGSize(width: cachedWidth, height: cachedHeight)
  }

  func disposeSharedState(destroySynchronously: Bool) {
    isDisposing = true
    cancelPendingRequests()

    let mpvHandle = mpv
    mpv = nil

    let destroy = {
      if let mpvHandle {
        mpv_set_wakeup_callback(mpvHandle, nil, nil)
        mpv_terminate_destroy(mpvHandle)
      }
    }

    if destroySynchronously {
      if DispatchQueue.getSpecific(key: queueKey) != nil {
        destroy()
      } else {
        queue.sync(execute: destroy)
      }
    } else {
      queue.async(execute: destroy)
    }
  }

  func applyGpuNextOptions() {
    guard mpv != nil else { return }
    setProperty("gpu-api", value: "vulkan")
    setProperty("gpu-context", value: "moltenvk")
    setProperty("vo", value: "gpu-next")
  }

  private func applySharedMpvOptions() {
    guard let mpv else { return }
    checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
    checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
    checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
    checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
    checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "yes"))
  }

  private func cancelPendingRequests() {
    pendingRequestsLock.lock()
    let pending = pendingRequests
    pendingRequests.removeAll()
    pendingRequestsLock.unlock()

    let error = NSError(
      domain: "mpv",
      code: -1,
      userInfo: [NSLocalizedDescriptionKey: "Player disposed"]
    )
    for (_, request) in pending {
      DispatchQueue.main.async {
        switch request {
        case .void(let completion):
          completion(.failure(error))
        case .getProperty(let completion):
          completion(.failure(error))
        }
      }
    }
  }

  private func registerRequest(_ request: PendingRequest) -> UInt64 {
    pendingRequestsLock.lock()
    defer { pendingRequestsLock.unlock() }

    let requestId = nextRequestId
    nextRequestId += 1
    pendingRequests[requestId] = request
    return requestId
  }

  private func takeRequest(_ requestId: UInt64) -> PendingRequest? {
    pendingRequestsLock.lock()
    defer { pendingRequestsLock.unlock() }
    return pendingRequests.removeValue(forKey: requestId)
  }

  private func mpvError(_ status: CInt) -> NSError {
    NSError(
      domain: "mpv",
      code: Int(status),
      userInfo: [NSLocalizedDescriptionKey: safeString(mpv_error_string(status))]
    )
  }

  private func completeRequestIfSubmissionFailed(requestId: UInt64, status: CInt) {
    guard status < 0, let request = takeRequest(requestId) else { return }
    let error = mpvError(status)
    DispatchQueue.main.async {
      switch request {
      case .void(let completion):
        completion(.failure(error))
      case .getProperty(let completion):
        completion(.failure(error))
      }
    }
  }

  private func completeVoidRequest(requestId: UInt64, error status: CInt) {
    guard let request = takeRequest(requestId) else { return }
    DispatchQueue.main.async {
      switch request {
      case .void(let completion):
        if status < 0 {
          completion(.failure(self.mpvError(status)))
        } else {
          completion(.success(()))
        }
      case .getProperty:
        break
      }
    }
  }

  private func completeGetPropertyRequest(_ event: mpv_event) {
    guard let request = takeRequest(event.reply_userdata) else { return }
    guard case .getProperty(let completion) = request else { return }

    var value: String?
    if event.error >= 0,
      let propertyPointer = event.data?.assumingMemoryBound(to: mpv_event_property.self)
    {
      let property = propertyPointer.pointee
      if property.format == MPV_FORMAT_STRING, let data = property.data {
        let cstring = data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee
        value = cstring.map { safeString($0) }
      }
    }

    DispatchQueue.main.async {
      completion(.success(value))
    }
  }

  private func readEvents() {
    queue.async { [weak self] in
      guard let self, !self.isDisposing, let mpv = self.mpv else { return }

      while true {
        let event = mpv_wait_event(mpv, 0)
        guard let event else { break }

        if event.pointee.event_id == MPV_EVENT_NONE {
          break
        }

        self.handleEvent(event.pointee)
      }
    }
  }

  private func handleEvent(_ event: mpv_event) {
    switch event.event_id {
    case MPV_EVENT_PROPERTY_CHANGE:
      guard let data = event.data else { break }
      let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
      let name = safeString(property.name)
      handlePropertyChange(name: name, property: property, replyUserdata: event.reply_userdata)

    case MPV_EVENT_COMMAND_REPLY:
      completeVoidRequest(requestId: event.reply_userdata, error: event.error)

    case MPV_EVENT_SET_PROPERTY_REPLY:
      completeVoidRequest(requestId: event.reply_userdata, error: event.error)

    case MPV_EVENT_GET_PROPERTY_REPLY:
      completeGetPropertyRequest(event)

    case MPV_EVENT_FILE_LOADED:
      DispatchQueue.main.async {
        self.delegate?.onEvent(name: "file-loaded", data: nil)
      }

    case MPV_EVENT_END_FILE:
      if let endFilePtr = event.data?.assumingMemoryBound(to: mpv_event_end_file.self) {
        let endFile = endFilePtr.pointee
        var data: [String: Any] = ["reason": Int(endFile.reason.rawValue)]
        if endFile.reason == MPV_END_FILE_REASON_ERROR {
          data["error"] = Int(endFile.error)
          data["message"] = safeString(mpv_error_string(endFile.error))
        }
        DispatchQueue.main.async {
          self.delegate?.onEvent(name: "end-file", data: data)
        }
      } else {
        DispatchQueue.main.async {
          self.delegate?.onEvent(name: "end-file", data: nil)
        }
      }

    case MPV_EVENT_SHUTDOWN:
      print("[MpvPlayerCore] MPV shutdown event")

    case MPV_EVENT_PLAYBACK_RESTART:
      DispatchQueue.main.async {
        self.delegate?.onEvent(name: "playback-restart", data: nil)
      }

    case MPV_EVENT_LOG_MESSAGE:
      if isBackgrounded { break }
      if let messagePointer = event.data?.assumingMemoryBound(to: mpv_event_log_message.self) {
        let message = messagePointer.pointee
        let prefix = message.prefix.map { safeString($0) } ?? ""
        let level = message.level.map { safeString($0) } ?? ""
        let text = message.text.map { safeString($0) } ?? ""

        DispatchQueue.main.async {
          self.delegate?.onEvent(
            name: "log-message",
            data: ["prefix": prefix, "level": level, "text": text]
          )
        }
      }

    default:
      break
    }
  }

  private func handlePropertyChange(name: String, property: mpv_event_property, replyUserdata: UInt64) {
    var value: Any?

    switch property.format {
    case MPV_FORMAT_DOUBLE:
      if let data = property.data {
        value = data.assumingMemoryBound(to: Double.self).pointee
      }

    case MPV_FORMAT_FLAG:
      if let data = property.data {
        value = data.assumingMemoryBound(to: Int32.self).pointee != 0
      }

    case MPV_FORMAT_NODE:
      if let data = property.data {
        let node = data.assumingMemoryBound(to: mpv_node.self).pointee
        value = convertNode(node)
      }

    case MPV_FORMAT_STRING:
      if let data = property.data {
        let cstring = data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee
        value = cstring.map { safeString($0) }
      }

    default:
      break
    }

    updateCachedProperty(name: name, value: value)

    if name == "video-params/sig-peak", let sigPeak = value as? Double {
      cacheLock.lock()
      lastSigPeak = sigPeak
      cacheLock.unlock()
      DispatchQueue.main.async {
        self.updateEDRMode(sigPeak: sigPeak)
      }
    }

    if Self.internalObserverIds.contains(replyUserdata) { return }
    if isBackgrounded && !Self.criticalProperties.contains(name) { return }

    DispatchQueue.main.async {
      self.delegate?.onPropertyChange(name: name, value: value)
    }
  }

  private func updateCachedProperty(name: String, value: Any?) {
    cacheLock.lock()
    defer { cacheLock.unlock() }

    switch name {
    case "pause":
      if let paused = value as? Bool { cachedPaused = paused }
    case "duration":
      if let duration = value as? Double { cachedDuration = duration }
    case "time-pos":
      if let timePos = value as? Double { cachedTimePos = timePos }
    case "width":
      if let width = value as? Double { cachedWidth = width }
    case "height":
      if let height = value as? Double { cachedHeight = height }
    default:
      break
    }
  }

  private func setCachedPaused(_ paused: Bool) {
    cacheLock.lock()
    cachedPaused = paused
    cacheLock.unlock()
  }

  private func convertNode(_ node: mpv_node) -> Any? {
    switch node.format {
    case MPV_FORMAT_STRING:
      return node.u.string.map { safeString($0) }

    case MPV_FORMAT_FLAG:
      return node.u.flag != 0

    case MPV_FORMAT_INT64:
      return node.u.int64

    case MPV_FORMAT_DOUBLE:
      return node.u.double_

    case MPV_FORMAT_NODE_ARRAY:
      guard let list = node.u.list?.pointee else { return nil }
      var array = [Any]()
      for index in 0..<Int(list.num) {
        if let item = convertNode(list.values[index]) {
          array.append(item)
        }
      }
      return array

    case MPV_FORMAT_NODE_MAP:
      guard let list = node.u.list?.pointee else { return nil }
      var dictionary = [String: Any]()
      for index in 0..<Int(list.num) {
        if let key = list.keys?[index].map({ safeString($0) }),
          let value = convertNode(list.values[index])
        {
          dictionary[key] = value
        }
      }
      return dictionary

    default:
      return nil
    }
  }

  func checkError(_ status: CInt) {
    if status < 0 {
      print("[MpvPlayerCore] MPV error: \(safeString(mpv_error_string(status)))")
    }
  }
}
