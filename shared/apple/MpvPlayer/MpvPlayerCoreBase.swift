import AVFoundation
import Foundation
import Libmpv
import QuartzCore

#if os(iOS) || os(tvOS)
  import UIKit
#elseif os(macOS)
  import Cocoa
  import Metal
#endif

protocol MpvPlayerDelegate: AnyObject {
  func onPropertyChange(name: String, value: Any?)
  func onEvent(name: String, data: [String: Any]?)
}

#if os(macOS)
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
  }
#else
  class MpvVideoLayer: AVSampleBufferDisplayLayer {}
#endif

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

struct ServerDisplayCriteria {
  let doviProfile: Int64
  let doviLevel: Int64
  let doviCompatibilityId: Int64?
  let fps: Double
  let width: Int32
  let height: Int32
  let gamma: String?
  let primaries: String?
  let colorMatrix: String?

  /// Whether the server metadata carried actual color/DoVi information —
  /// only then may the prime lock out mpv-derived color updates.
  var hasColorInfo: Bool {
    doviProfile > 0 || gamma != nil || primaries != nil || colorMatrix != nil
  }
}

class MpvPlayerCoreBase: NSObject {
  weak var delegate: MpvPlayerDelegate?

  #if os(macOS)
    var metalLayer: MpvMetalLayer?
  #else
    var videoLayer: MpvVideoLayer?
  #endif
  var mpv: OpaquePointer?
  var isInitialized = false
  var isDisposing = false
  var isPipActive = false
  var isBackgrounded = false
  private var wakeupCallbackContext: UnsafeMutableRawPointer?
  private var cachedHDREnabled = true
  private var cachedLastSigPeak = 0.0
  private var cachedDoviProfile: Int64 = 0
  private var cachedDoviLevel: Int64 = 0
  private var cachedContainerFps: Double = 0
  private var cachedVideoGamma: String?
  private var cachedVideoPrimaries: String?
  private var cachedVideoColorMatrix: String?
  private var serverDisplayCriteriaActive = false
  private var serverCriteriaLocksColor = false
  private var lastServerCriteria: ServerDisplayCriteria?
  private var cachedDvConversionMode = "auto"
  private var cachedDvConversionLogEnabled = false
  var hdrEnabled: Bool {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedHDREnabled
  }
  var lastSigPeak: Double {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedLastSigPeak
  }
  var doviProfile: Int64 {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedDoviProfile
  }
  var doviLevel: Int64 {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedDoviLevel
  }
  var containerFps: Double {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedContainerFps
  }

  /// Properties that must still flow to Dart while backgrounded (state-critical).
  private static let criticalProperties: Set<String> = [
    "pause", "eof-reached", "paused-for-cache", "time-pos", "duration", "seekable",
  ]

  private static let internalSigPeakObserverId: UInt64 = UInt64.max - 1
  private static let internalWidthObserverId: UInt64 = UInt64.max - 2
  private static let internalHeightObserverId: UInt64 = UInt64.max - 3
  private static let internalDoviProfileObserverId: UInt64 = UInt64.max - 4
  private static let internalDoviLevelObserverId: UInt64 = UInt64.max - 5
  private static let internalContainerFpsObserverId: UInt64 = UInt64.max - 6
  private static let internalVideoGammaObserverId: UInt64 = UInt64.max - 7
  private static let internalVideoPrimariesObserverId: UInt64 = UInt64.max - 8
  private static let internalVideoColorMatrixObserverId: UInt64 = UInt64.max - 9
  private static let internalObserverIds: Set<UInt64> = [
    internalSigPeakObserverId,
    internalWidthObserverId,
    internalHeightObserverId,
    internalDoviProfileObserverId,
    internalDoviLevelObserverId,
    internalContainerFpsObserverId,
    internalVideoGammaObserverId,
    internalVideoPrimariesObserverId,
    internalVideoColorMatrixObserverId,
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
  private var currentPanscan = 0.0
  private var aspectOverrideActive = false

  override init() {
    super.init()
    queue.setSpecific(key: queueKey, value: ())
  }

  func configurePlatformMpvOptions() {}

  func updateEDRMode(sigPeak: Double) {}

  @discardableResult
  func updateDisplayCriteria(
    doviProfile: Int64,
    doviLevel: Int64,
    doviCompatibilityId: Int64?,
    fps: Double,
    width: Int32,
    height: Int32,
    sigPeak: Double,
    gamma: String?,
    primaries: String?,
    colorMatrix: String?
  ) -> Bool { false }

  /// Whether the mpv-derived caches indicate an HDR/DV source — mirrors the
  /// Dart-side MediaDisplayCriteria.isHdr tag check. Call under cacheLock.
  private static func looksHdr(
    doviProfile: Int64, sigPeak: Double, gamma: String?, primaries: String?, colorMatrix: String?
  ) -> Bool {
    if doviProfile > 0 || sigPeak > 1 { return true }
    let tags = [gamma, primaries, colorMatrix]
      .compactMap { $0?.lowercased() }
      .joined(separator: " ")
      .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
    return ["hlg", "arib", "pq", "smpte2084", "st2084", "bt2020"].contains { tags.contains($0) }
  }

  func scheduleDisplayCriteriaUpdate() {
    cacheLock.lock()
    if serverDisplayCriteriaActive {
      // A color-bearing server prime owns the display mode for the item. An
      // fps-only prime is just an early hint: demote it once the decoded
      // stream proves HDR/DV so the real color tags reach the display,
      // otherwise keep suppressing redundant SDR re-applies.
      if serverCriteriaLocksColor
        || !Self.looksHdr(
          doviProfile: cachedDoviProfile,
          sigPeak: cachedLastSigPeak,
          gamma: cachedVideoGamma,
          primaries: cachedVideoPrimaries,
          colorMatrix: cachedVideoColorMatrix
        )
      {
        cacheLock.unlock()
        return
      }
      serverDisplayCriteriaActive = false
      serverCriteriaLocksColor = false
      lastServerCriteria = nil
    }
    let profile = cachedDoviProfile
    let level = cachedDoviLevel
    let fps = cachedContainerFps
    let width = Int32(cachedWidth)
    let height = Int32(cachedHeight)
    let sigPeak = cachedLastSigPeak
    let gamma = cachedVideoGamma
    let primaries = cachedVideoPrimaries
    let colorMatrix = cachedVideoColorMatrix
    cacheLock.unlock()

    DispatchQueue.main.async { [weak self] in
      self?.updateDisplayCriteria(
        doviProfile: profile,
        doviLevel: level,
        doviCompatibilityId: nil,
        fps: fps,
        width: width,
        height: height,
        sigPeak: sigPeak,
        gamma: gamma,
        primaries: primaries,
        colorMatrix: colorMatrix
      )
    }
  }

  func setServerDisplayCriteria(_ criteria: ServerDisplayCriteria?, completion: ((Bool) -> Void)? = nil) {
    cacheLock.lock()
    serverDisplayCriteriaActive = criteria != nil
    serverCriteriaLocksColor = criteria?.hasColorInfo ?? false
    lastServerCriteria = criteria
    cacheLock.unlock()

    let apply = { [weak self] in
      guard let self else { return }
      guard let criteria else {
        let applied = self.updateDisplayCriteria(
          doviProfile: 0,
          doviLevel: 0,
          doviCompatibilityId: nil,
          fps: 0,
          width: 0,
          height: 0,
          sigPeak: 0,
          gamma: nil,
          primaries: nil,
          colorMatrix: nil
        )
        completion?(applied)
        return
      }

      let applied = self.updateDisplayCriteria(
        doviProfile: criteria.doviProfile,
        doviLevel: criteria.doviLevel,
        doviCompatibilityId: criteria.doviCompatibilityId,
        fps: criteria.fps,
        width: criteria.width,
        height: criteria.height,
        sigPeak: 0,
        gamma: criteria.gamma,
        primaries: criteria.primaries,
        colorMatrix: criteria.colorMatrix
      )
      if !applied {
        self.cacheLock.lock()
        self.serverDisplayCriteriaActive = false
        self.serverCriteriaLocksColor = false
        self.cacheLock.unlock()
        self.scheduleDisplayCriteriaUpdate()
      }
      completion?(applied)
    }

    if Thread.isMainThread {
      apply()
    } else {
      DispatchQueue.main.async(execute: apply)
    }
  }

  /// Re-evaluate the tvOS HDMI display mode using the most recent criteria.
  /// On tvOS the HDR toggle only reaches the display through this path, so the
  /// runtime toggle calls this to switch DV/HDR ⇄ SDR without reloading.
  func reapplyDisplayCriteria() {
    cacheLock.lock()
    let criteria = lastServerCriteria
    cacheLock.unlock()

    if let criteria {
      setServerDisplayCriteria(criteria)
    } else {
      scheduleDisplayCriteriaUpdate()
    }
  }

  func setupMpv() -> Bool {
    #if os(macOS)
      guard let renderLayer = metalLayer else { return false }
      configureMoltenVKPlacementHeaps()
    #else
      guard let renderLayer = videoLayer else { return false }
    #endif

    applyDvConversionModeEnvironment()

    let created = createMpvContext { [self] in
      guard let mpv else { return }
      var layer = Int64(Int(bitPattern: Unmanaged.passUnretained(renderLayer).toOpaque()))
      checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &layer))
      applySharedMpvOptions()
      configurePlatformMpvOptions()
    }
    guard created, let mpv else { return false }

    mpv_observe_property(mpv, Self.internalSigPeakObserverId, "video-params/sig-peak", MPV_FORMAT_DOUBLE)
    mpv_observe_property(mpv, Self.internalWidthObserverId, "width", MPV_FORMAT_DOUBLE)
    mpv_observe_property(mpv, Self.internalHeightObserverId, "height", MPV_FORMAT_DOUBLE)
    mpv_observe_property(
      mpv, Self.internalDoviProfileObserverId,
      "current-tracks/video/dolby-vision-profile", MPV_FORMAT_INT64)
    mpv_observe_property(
      mpv, Self.internalDoviLevelObserverId,
      "current-tracks/video/dolby-vision-level", MPV_FORMAT_INT64)
    mpv_observe_property(
      mpv, Self.internalContainerFpsObserverId,
      "container-fps", MPV_FORMAT_DOUBLE)
    mpv_observe_property(mpv, Self.internalVideoGammaObserverId, "video-params/gamma", MPV_FORMAT_STRING)
    mpv_observe_property(mpv, Self.internalVideoPrimariesObserverId, "video-params/primaries", MPV_FORMAT_STRING)
    mpv_observe_property(
      mpv, Self.internalVideoColorMatrixObserverId,
      "video-params/colormatrix", MPV_FORMAT_STRING)
    return true
  }

  /// Create the mpv context, apply pre-init options via `configure`, run
  /// `mpv_initialize`, and install the wakeup callback. Everything here is
  /// instance-scoped (per-instance dispatch queue, request table, and retained
  /// wakeup context), so the video core and the audio-only core can each own
  /// an independent context and be created/destroyed at any time.
  func createMpvContext(configure: () -> Void) -> Bool {
    mpv = mpv_create()
    guard let mpv else {
      print("[MpvPlayerCore] Failed to create MPV context")
      return false
    }

    // TEMP: always "v" (tvOS builds in release) so the avfoundation VO's
    // osd-perf timing lines show up — restore the DEBUG/warn split after the
    // subtitle-timing investigation.
    checkError(mpv_request_log_messages(mpv, "v"))

    configure()

    let initResult = mpv_initialize(mpv)
    if initResult < 0 {
      print("[MpvPlayerCore] mpv_initialize failed: \(safeString(mpv_error_string(initResult)))")
      mpv_terminate_destroy(mpv)
      self.mpv = nil
      return false
    }

    // mpv stores this context without retaining it. Retain manually so the
    // Swift core cannot deallocate while mpv can still fire wakeup callbacks.
    let wakeupContext = Unmanaged.passRetained(self).toOpaque()
    wakeupCallbackContext = wakeupContext

    mpv_set_wakeup_callback(
      mpv,
      { context in
        guard let context else { return }
        let core = Unmanaged<MpvPlayerCoreBase>.fromOpaque(context).takeUnretainedValue()
        core.readEvents()
      },
      wakeupContext
    )
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
    #if targetEnvironment(simulator)
      if name == "hwdec" {
        if value != "no" {
          print("[MpvPlayerCore] Simulator does not support hardware decoding; forcing hwdec=no")
        }
        setRawStringPropertyAsync(name, value: "no", completion: completion)
        return
      }
    #endif

    if isManagedRendererProperty(name) {
      print("[MpvPlayerCore] Ignoring managed renderer property: \(name)=\(value)")
      completion(.success(()))
      return
    }

    updateVideoGravityIfNeeded(name: name, value: value)

    if name == "pause" {
      setCachedPaused(value == "yes" || value == "true" || value == "1")
    }

    if name == "hdr-enabled" {
      let enabled = value == "yes" || value == "true" || value == "1"
      setHDREnabled(enabled, completion: completion)
      return
    }

    if name == "dv-conversion-mode" {
      setDvConversionMode(value)
      completion(.success(()))
      return
    }

    if name == "dv-conversion-log" {
      setDvConversionLogEnabled(parseBoolProperty(value))
      completion(.success(()))
      return
    }

    setRawStringPropertyAsync(name, value: value, completion: completion)
  }

  private func parseBoolProperty(_ value: String) -> Bool {
    switch value.lowercased() {
    case "1", "true", "yes", "on":
      return true
    default:
      return false
    }
  }

  private func normalizeDvConversionMode(_ value: String) -> String {
    switch value.lowercased() {
    case "disabled", "native":
      return "disabled"
    case "dv81", "p8", "p7_to_p8", "p7-to-p8":
      return "dv81"
    case "hevc", "hevc_strip", "p7_to_hevc", "p7-to-hevc":
      return "hevc_strip"
    default:
      return "auto"
    }
  }

  private func applyDvConversionModeEnvironment() {
    cacheLock.lock()
    let mode = cachedDvConversionMode
    let logEnabled = cachedDvConversionLogEnabled
    cacheLock.unlock()

    setenv("PLEZY_DV_CONVERSION_MODE", mode, 1)
    setenv("PLEZY_DV_CONVERSION_LOG", logEnabled ? "1" : "0", 1)
  }

  func setDvConversionMode(_ mode: String) {
    cacheLock.lock()
    cachedDvConversionMode = normalizeDvConversionMode(mode)
    let normalized = cachedDvConversionMode
    let logEnabled = cachedDvConversionLogEnabled
    cacheLock.unlock()

    applyDvConversionModeEnvironment()
    if logEnabled {
      print("[MpvPlayerCore] DV conversion mode: \(normalized)")
    }
  }

  func setDvConversionLogEnabled(_ enabled: Bool) {
    cacheLock.lock()
    cachedDvConversionLogEnabled = enabled
    let mode = cachedDvConversionMode
    cacheLock.unlock()

    applyDvConversionModeEnvironment()
    if enabled {
      print("[MpvPlayerCore] DV conversion logging enabled (mode: \(mode))")
    }
  }

  func getDvConversionMode() -> String {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedDvConversionMode
  }

  func getDvConversionLogEnabled() -> Bool {
    cacheLock.lock()
    defer { cacheLock.unlock() }
    return cachedDvConversionLogEnabled
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
    cachedHDREnabled = enabled
    let sigPeak = cachedLastSigPeak
    cacheLock.unlock()

    print("[MpvPlayerCore] HDR enabled: \(enabled)")

    setRawStringPropertyAsync(
      "target-colorspace-hint",
      value: enabled ? "auto" : "no",
      completion: completion ?? { _ in }
    )

    DispatchQueue.main.async {
      self.updateEDRMode(sigPeak: sigPeak)
    }

    // On tvOS the toggle only takes effect through the HDMI display-mode path
    // (target-colorspace-hint is inert in the avfoundation VO and EDR is
    // iOS-only), so re-evaluate the display criteria with the new flag.
    #if os(tvOS)
      DispatchQueue.main.async {
        self.reapplyDisplayCriteria()
      }
    #endif
  }

  /// PiP presents the AVSampleBufferDisplayLayer directly, so subtitles must
  /// be composited into the video samples instead of the inline OSD layer.
  func setPipSubtitleCompositing(_ enabled: Bool) {
    #if os(iOS)
      let value = enabled ? "yes" : "no"
      setRawStringPropertyAsync("avfoundation-pip-composite-osd", value: value) { result in
        if case .failure(let error) = result {
          print(
            "[MpvPlayerCore] Failed to set PiP subtitle compositing "
              + "to \(value): \(error.localizedDescription)"
          )
        }
      }
    #endif
  }

  func getPropertyAsync(_ name: String, completion: @escaping (Result<String?, Error>) -> Void) {
    if name == "dv-conversion-mode" {
      completion(.success(getDvConversionMode()))
      return
    }

    if name == "dv-conversion-log" {
      completion(.success(getDvConversionLogEnabled() ? "yes" : "no"))
      return
    }

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

    cacheLock.lock()
    cachedDoviProfile = 0
    cachedDoviLevel = 0
    cachedContainerFps = 0
    cachedLastSigPeak = 0
    cachedVideoGamma = nil
    cachedVideoPrimaries = nil
    cachedVideoColorMatrix = nil
    serverDisplayCriteriaActive = false
    cacheLock.unlock()

    let mpvHandle = mpv
    let callbackContext = wakeupCallbackContext
    mpv = nil
    wakeupCallbackContext = nil

    let destroy = {
      if let mpvHandle {
        mpv_set_wakeup_callback(mpvHandle, nil, nil)
        mpv_terminate_destroy(mpvHandle)
      }
      if let callbackContext {
        Unmanaged<MpvPlayerCoreBase>.fromOpaque(callbackContext).release()
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

  private func applySharedMpvOptions() {
    guard let mpv else { return }
    #if os(macOS)
      checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
      checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
      checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
      checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
    #else
      checkError(mpv_set_option_string(mpv, "vo", "avfoundation"))
      #if targetEnvironment(simulator)
        checkError(mpv_set_option_string(mpv, "avfoundation-composite-osd", "no"))
        checkError(mpv_set_option_string(mpv, "hwdec", "no"))
      #elseif os(tvOS)
        // tvOS HDR is HDMI mode switching, not EDR — an SDR sibling layer
        // doesn't dim the video, so skip the per-frame CI composite that
        // round-trips BT.2020/PQ through linear P3.
        checkError(mpv_set_option_string(mpv, "avfoundation-composite-osd", "no"))
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
      #else
        checkError(mpv_set_option_string(mpv, "avfoundation-composite-osd", "no"))
        checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
      #endif
    #endif
    checkError(mpv_set_option_string(mpv, "hwdec-codecs", "all"))
    checkError(mpv_set_option_string(mpv, "hwdec-software-fallback", "yes"))
    checkError(mpv_set_option_string(mpv, "target-colorspace-hint", "auto"))
    // Pause on the last frame at EOF instead of unloading the file, so seeking
    // back after the video ends still works (matches Linux/Windows).
    checkError(mpv_set_option_string(mpv, "keep-open", "yes"))
  }

  #if os(macOS)
    private func configureMoltenVKPlacementHeaps() {
      guard let device = MTLCreateSystemDefaultDevice() else { return }
      let supportsPlacementHeaps = device.supportsFamily(.apple2) || device.supportsFamily(.mac2)
      if !supportsPlacementHeaps {
        setenv("MVK_CONFIG_USE_MTLHEAP", "0", 1)
      }
    }
  #endif

  private func isManagedRendererProperty(_ name: String) -> Bool {
    name == "vo" || name == "wid" || name == "gpu-api" || name == "gpu-context"
      || name == "avfoundation-composite-osd" || name == "avfoundation-pip-composite-osd"
  }

  private func updateVideoGravityIfNeeded(name: String, value: String) {
    #if os(macOS)
      return
    #else
      let gravity: AVLayerVideoGravity
      cacheLock.lock()
      switch name {
      case "panscan":
        currentPanscan = Double(value) ?? 0
      case "video-aspect-override":
        aspectOverrideActive = value != "no" && value != "-1" && value != "0"
      default:
        cacheLock.unlock()
        return
      }

      if aspectOverrideActive {
        gravity = .resize
      } else if currentPanscan > 0 {
        gravity = .resizeAspectFill
      } else {
        gravity = .resizeAspect
      }
      cacheLock.unlock()

      DispatchQueue.main.async { [weak self] in
        self?.videoLayer?.videoGravity = gravity
      }
    #endif
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

    case MPV_FORMAT_INT64:
      if let data = property.data {
        value = data.assumingMemoryBound(to: Int64.self).pointee
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
      cachedLastSigPeak = sigPeak
      cacheLock.unlock()
      DispatchQueue.main.async {
        self.updateEDRMode(sigPeak: sigPeak)
      }
      scheduleDisplayCriteriaUpdate()
    }

    switch name {
    case "current-tracks/video/dolby-vision-profile":
      cacheLock.lock()
      cachedDoviProfile = (value as? Int64) ?? 0
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "current-tracks/video/dolby-vision-level":
      cacheLock.lock()
      cachedDoviLevel = (value as? Int64) ?? 0
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "container-fps":
      cacheLock.lock()
      cachedContainerFps = (value as? Double) ?? 0
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/gamma":
      cacheLock.lock()
      cachedVideoGamma = value as? String
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/primaries":
      cacheLock.lock()
      cachedVideoPrimaries = value as? String
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/colormatrix":
      cacheLock.lock()
      cachedVideoColorMatrix = value as? String
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "width", "height":
      scheduleDisplayCriteriaUpdate()
    default:
      break
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
