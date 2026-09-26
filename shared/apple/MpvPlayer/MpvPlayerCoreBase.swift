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

struct MpvLifecycleUnavailableError: LocalizedError {
  let errorDescription: String?

  init(_ description: String) {
    errorDescription = description
  }
}

/// Runtime gate for the player's native debug logging.
///
/// Swift `print`/`NSLog` are not compiled out of a release build, and the
/// caller builds the interpolated string before the call runs, so an ungated
/// trace on a frame, layout, or surface callback costs real work on every
/// user's device. Debug traces go through `MpvLog.debug`, whose `@autoclosure`
/// message is never evaluated while the gate is shut.
///
/// The gate follows the app's "Debug Logging" setting: Dart pushes the mpv log
/// level over `setLogLevel`, and a verbose level opens this too. DEBUG builds
/// start open and release builds start silent, matching the `defaultLogLevel`
/// that `createMpvContext` requests from mpv.
enum MpvLog {
  #if DEBUG
    static var isDebugEnabled = true
  #else
    static var isDebugEnabled = false
  #endif

  /// Whether `level` - an mpv log level as delivered by `setLogLevel` - means
  /// the user asked for verbose diagnostics.
  static func isVerbose(_ level: String) -> Bool {
    level == "v" || level == "debug" || level == "trace"
  }

  /// A diagnostic trace. Dropped - argument unevaluated - while the gate is shut.
  static func debug(_ message: @autoclosure () -> String) {
    guard isDebugEnabled else { return }
    print(message())
  }

  /// A failure worth keeping in a release device log. Always emitted.
  static func error(_ message: String) {
    print(message)
  }
}

protocol MpvPlayerDelegate: AnyObject {
  func onPropertyChange(name: String, value: Any?, sourceId: Int64?)
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

    // MoltenVK sets this from libmpv's VO thread when it tags the layer for
    // the negotiated swapchain colorspace (on for PQ, HLG and Display P3, off
    // for sRGB and pass-through). The screen only enters EDR mode for a write
    // made on the main thread, so marshal it there; the colorspace itself
    // takes effect from any thread.
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

final class MpvWakeupCallbackContext {
  private let lock = NSLock()
  private weak var core: MpvPlayerCoreBase?

  init(core: MpvPlayerCoreBase) {
    self.core = core
  }

  func dispatchWakeup() {
    lock.lock()
    defer { lock.unlock() }
    core?.readEventsFromCallback()
  }

  func detach() {
    lock.lock()
    core = nil
    lock.unlock()
  }
}

class MpvPlayerCoreBase: NSObject {
  weak var delegate: MpvPlayerDelegate?

  #if os(macOS)
    var metalLayer: MpvMetalLayer?
  #else
    var videoLayer: MpvVideoLayer?
  #endif
  var isInitialized = false
  var isPipActive = false

  private struct LifecycleState {
    var mpv: OpaquePointer?
    var isTerminal = false
    var isBackgrounded = false
    var wakeupCallbackContext: UnsafeMutableRawPointer?
  }

  private let lifecycleLock = NSLock()
  private var lifecycleState = LifecycleState()
  private var cachedHDREnabled = true
  private var cachedLastSigPeak = 0.0
  private var cachedDoviProfile: Int64 = 0
  private var cachedDoviLevel: Int64 = 0
  private var cachedContainerFps: Double = 0
  private var cachedDeinterlaceActive = false
  private var cachedEstimatedFps: Double = 0
  private var displayCriteriaUpdateScheduled = false
  /// No stream is being presented: between a file's END_FILE (or START_FILE)
  /// and the next PLAYBACK_RESTART, and before the first file. While held,
  /// `applyDisplayCriteriaFromCaches` commits nothing, so the previous
  /// file's criteria stay on the HDMI link until the next file's first frame
  /// proves whether they need to change.
  private var displayCriteriaHeld = true
  private var cachedVideoGamma: String?
  private var cachedVideoPrimaries: String?
  private var cachedVideoColorMatrix: String?
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
  /// The track properties change about once per file, and Dart's track
  /// selection for an episode that auto-advances in PiP or background playback
  /// waits on them; dropped, that episode loses its audio/subtitle choice.
  private static let criticalProperties: Set<String> = [
    "pause", "eof-reached", "paused-for-cache", "time-pos", "duration", "seekable",
    "track-list", "aid", "sid", "secondary-sid",
  ]

  /// Latest value of each other property dropped while backgrounded, replayed
  /// when the core leaves the background: mpv reports a property again only
  /// when it changes, so a dropped update would otherwise stay lost (e.g. the
  /// initial audio-device-list of a macOS core that starts hidden). Accessed
  /// only on `queue`.
  private var backgroundedPropertyChanges: [String: (value: Any?, sourceId: Int64?)] = [:]

  private static let internalSigPeakObserverId: UInt64 = UInt64.max - 1
  private static let internalWidthObserverId: UInt64 = UInt64.max - 2
  private static let internalHeightObserverId: UInt64 = UInt64.max - 3
  private static let internalDoviProfileObserverId: UInt64 = UInt64.max - 4
  private static let internalDoviLevelObserverId: UInt64 = UInt64.max - 5
  private static let internalContainerFpsObserverId: UInt64 = UInt64.max - 6
  private static let internalVideoGammaObserverId: UInt64 = UInt64.max - 7
  private static let internalVideoPrimariesObserverId: UInt64 = UInt64.max - 8
  private static let internalVideoColorMatrixObserverId: UInt64 = UInt64.max - 9
  private static let internalDeinterlaceActiveObserverId: UInt64 = UInt64.max - 10
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
    internalDeinterlaceActiveObserverId,
  ]

  let queue = DispatchQueue(label: "mpv", qos: .userInitiated)
  private let queueKey = DispatchSpecificKey<Void>()
  /// The most recent playlist entry announced by START_FILE. Event dequeue
  /// runs serially on `queue`; pass this value into delegate dispatch rather
  /// than reading it later on the main queue.
  private var activeSourceId: Int64?

  private enum PendingRequest {
    case void((Result<Void, Error>) -> Void)
    /// A command reply. The payload is the playlist entry `loadfile` created
    /// (the `sourceId` that entry's events carry); nil for every other command.
    case command((Result<Int64?, Error>) -> Void)
    case getProperty((Result<String?, Error>) -> Void)

    func fail(with error: Error) {
      switch self {
      case .void(let completion):
        completion(.failure(error))
      case .command(let completion):
        completion(.failure(error))
      case .getProperty(let completion):
        completion(.failure(error))
      }
    }
  }

  private var pendingRequests: [UInt64: PendingRequest] = [:]
  private let pendingRequestsLock = NSLock()
  private var nextRequestId: UInt64 = 1

  private let cacheLock = NSLock()
  private var cachedPaused = true
  private var confirmedPaused = true
  private var resolvedPauseGeneration: UInt64 = 0
  private var pauseIntentGeneration: UInt64 = 0
  private var pauseObservationRevision: UInt64 = 0
  private var pendingPauseIntents: [UInt64: Bool] = [:]
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

  @discardableResult
  func beginDisposal() -> Bool {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    guard !lifecycleState.isTerminal else { return false }
    lifecycleState.isTerminal = true
    return true
  }

  func setBackgrounded(_ backgrounded: Bool) {
    lifecycleLock.lock()
    lifecycleState.isBackgrounded = backgrounded
    lifecycleLock.unlock()
    guard !backgrounded else { return }
    queue.async { [weak self] in
      self?.replayBackgroundedPropertyChanges()
    }
  }

  /// Runs on `queue` after property events that saw the core foregrounded, so
  /// a live delivery has already removed its stale entry here.
  private func replayBackgroundedPropertyChanges() {
    guard !isLifecycleBackgrounded, !backgroundedPropertyChanges.isEmpty else { return }
    let changes = backgroundedPropertyChanges
    backgroundedPropertyChanges.removeAll()
    for (name, change) in changes {
      dispatchDelegateProperty(name: name, value: change.value, sourceId: change.sourceId)
    }
  }

  var hasActiveMpv: Bool {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    return !lifecycleState.isTerminal && lifecycleState.mpv != nil
  }

  private var isLifecycleActive: Bool {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    return !lifecycleState.isTerminal
  }

  private var isLifecycleBackgrounded: Bool {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    return lifecycleState.isBackgrounded
  }

  private func withActiveMpv<T>(_ body: (OpaquePointer) -> T) -> T? {
    lifecycleLock.lock()
    defer { lifecycleLock.unlock() }
    guard !lifecycleState.isTerminal, let mpv = lifecycleState.mpv else { return nil }
    return body(mpv)
  }

  func configurePlatformMpvOptions(mpv: OpaquePointer) {}

  func updateEDRMode(sigPeak: Double) {}

  /// Platform hook fed by `scheduleDisplayCriteriaUpdate` with the decoded
  /// stream's properties (mpv is the only source — no server metadata). The
  /// tvOS core drives `AVDisplayManager.preferredDisplayCriteria` from it;
  /// other platforms ignore it. Always called on the main thread. Returns
  /// whether criteria were applied.
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

  /// Re-evaluate the display criteria from the cached mpv properties. Every
  /// observer feeding those caches calls this, as does the tvOS HDR toggle:
  /// there the toggle only reaches the HDMI link through this path, so it
  /// switches DV/HDR ⇄ SDR without reloading.
  ///
  /// Coalesced: a video reconfig delivers fps, dimensions, and every color
  /// tag as separate notifications; one main-thread pass snapshots the
  /// caches instead of applying each partial delivery. Coalescing is best
  /// effort — the main thread can run between two deliveries — so it is not
  /// what keeps the snapshot coherent. That is `displayCriteriaHeld` plus
  /// the synchronous PLAYBACK_RESTART read: no commit happens between files,
  /// and the first commit for a file comes from one authoritative snapshot.
  func scheduleDisplayCriteriaUpdate() {
    cacheLock.lock()
    let alreadyScheduled = displayCriteriaUpdateScheduled
    displayCriteriaUpdateScheduled = true
    cacheLock.unlock()
    if alreadyScheduled { return }

    DispatchQueue.main.async { [weak self] in
      self?.applyDisplayCriteriaFromCaches()
    }
  }

  private func applyDisplayCriteriaFromCaches() {
    cacheLock.lock()
    displayCriteriaUpdateScheduled = false
    if displayCriteriaHeld {
      cacheLock.unlock()
      return
    }
    var profile = cachedDoviProfile
    var level = cachedDoviLevel
    var compatibilityId: Int64?
    // The stream is presented one frame per field when mpv's own
    // deinterlacer is active (bwdif send_field, d3d11vpp, vavpp all emit
    // fields) or when the measured cadence says the decoder did it; either
    // way the presented rate is twice the container rate (#2322).
    let fieldOutput =
      cachedDeinterlaceActive
      || Self.presentsFields(container: cachedContainerFps, presented: cachedEstimatedFps)
    let fps = Self.nominalRefreshRate(fieldOutput ? cachedContainerFps * 2 : cachedContainerFps)
    let width = Int32(cachedWidth)
    let height = Int32(cachedHeight)
    let sigPeak = cachedLastSigPeak
    var gamma = cachedVideoGamma
    var primaries = cachedVideoPrimaries
    var colorMatrix = cachedVideoColorMatrix
    if profile == 7 {
      // The track property reports the bitstream's profile 7, but the fork
      // converts P7 to 8.1 in `auto`/`dv81` and strips it to its HDR10 base
      // layer otherwise — ask the display for what the decoder emits.
      if cachedDvConversionMode == "auto" || cachedDvConversionMode == "dv81" {
        profile = 8
      } else {
        profile = 0
        level = 0
      }
      compatibilityId = 1
      gamma = gamma ?? "smpte2084"
      primaries = primaries ?? "bt2020"
      colorMatrix = colorMatrix ?? "bt2020nc"
    }
    cacheLock.unlock()

    updateDisplayCriteria(
      doviProfile: profile,
      doviLevel: level,
      doviCompatibilityId: compatibilityId,
      fps: fps,
      width: width,
      height: height,
      sigPeak: sigPeak,
      gamma: gamma,
      primaries: primaries,
      colorMatrix: colorMatrix
    )
  }

  /// Whether the measured output cadence (`estimated-vf-fps`, one sample
  /// already at the first shown frame) is the container rate doubled. The
  /// band absorbs Matroska's millisecond timestamp rounding (a 16.68 ms
  /// field reads as 16 or 17 ms) and one duplicated timestamp in a ten-frame
  /// window (2.22) while rejecting duplicate-every-frame, dropped, or
  /// telecined cadences (3.0, 0.5, 1.25). Mirrors Dart's
  /// `PlayerOutputFormat.presentsFields`.
  static func presentsFields(container: Double, presented: Double) -> Bool {
    guard container > 0, presented > 0 else { return false }
    let ratio = presented / container
    return ratio > 1.7 && ratio < 2.3
  }

  /// Rates a TV advertises display modes for, in Hz.
  private static let nominalRefreshRates: [Double] = [
    23.976, 24, 25, 29.97, 30, 48, 50, 59.94, 60, 100, 119.88, 120,
  ]

  /// The rate to ask AVDisplayManager for: the nearest nominal rate when the
  /// presented rate is within 1% of one (FFmpeg's own band for rounding a
  /// guessed frame rate to a standard one), otherwise `fps` unchanged.
  /// Container rates are declared or averaged, never measured — a 29.97i
  /// capture reads 29.95784, an MKV with a 42 ms DefaultDuration 23.8095 —
  /// and the TV only has modes for the nominal rates. Android and Windows
  /// tolerate the raw rate because they pick the mode themselves
  /// (`DisplayModeSelector`, `DisplayModeService`); tvOS delegates the pick
  /// to the display manager, so the request itself has to be nominal.
  static func nominalRefreshRate(_ fps: Double) -> Double {
    guard fps > 0 else { return 0 }
    guard let nearest = nominalRefreshRates.min(by: { abs($0 - fps) < abs($1 - fps) }) else { return fps }
    return abs(nearest - fps) / nearest < 0.01 ? nearest : fps
  }

  func setupMpv() -> Bool {
    #if os(macOS)
      guard let renderLayer = metalLayer else { return false }
      configureMoltenVKPlacementHeaps()
    #else
      guard let renderLayer = videoLayer else { return false }
    #endif

    applyDvConversionModeEnvironment()

    let created = createMpvContext { [self] mpv in
      var layer = Int64(Int(bitPattern: Unmanaged.passUnretained(renderLayer).toOpaque()))
      checkError(mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &layer))
      applySharedMpvOptions(mpv: mpv)
      configurePlatformMpvOptions(mpv: mpv)
    }
    guard created else { return false }

    let observed: Void? = withActiveMpv { mpv in
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
      mpv_observe_property(
        mpv, Self.internalDeinterlaceActiveObserverId,
        "deinterlace-active", MPV_FORMAT_FLAG)
      mpv_observe_property(mpv, Self.internalVideoGammaObserverId, "video-params/gamma", MPV_FORMAT_STRING)
      mpv_observe_property(mpv, Self.internalVideoPrimariesObserverId, "video-params/primaries", MPV_FORMAT_STRING)
      mpv_observe_property(
        mpv, Self.internalVideoColorMatrixObserverId,
        "video-params/colormatrix", MPV_FORMAT_STRING)
    }
    return observed != nil
  }

  /// Create the mpv context, apply pre-init options via `configure`, run
  /// `mpv_initialize`, and install the wakeup callback. Everything here is
  /// instance-scoped (per-instance dispatch queue, request table, and retained
  /// wakeup context), so the video core and the audio-only core can each own
  /// an independent context and be created/destroyed at any time.
  func createMpvContext(configure: (OpaquePointer) -> Void) -> Bool {
    guard let mpv = mpv_create() else {
      MpvLog.error("[MpvPlayerCore] Failed to create MPV context")
      return false
    }

    #if DEBUG
      let defaultLogLevel = "v"
    #else
      let defaultLogLevel = "warn"
    #endif
    checkError(mpv_request_log_messages(mpv, defaultLogLevel))

    configure(mpv)

    let initResult = mpv_initialize(mpv)
    if initResult < 0 {
      MpvLog.error("[MpvPlayerCore] mpv_initialize failed: \(safeString(mpv_error_string(initResult)))")
      mpv_terminate_destroy(mpv)
      return false
    }

    // mpv stores this context without retaining it. The core owns the context,
    // while the context keeps only a weak callback target; disposal atomically
    // detaches it before removing the C callback. A late callback can therefore
    // neither retain/dereference a dead core nor enqueue work against a replacement.
    let callbackOwner = MpvWakeupCallbackContext(core: self)
    let wakeupContext = Unmanaged.passRetained(callbackOwner).toOpaque()

    lifecycleLock.lock()
    guard !lifecycleState.isTerminal, lifecycleState.mpv == nil else {
      lifecycleLock.unlock()
      mpv_terminate_destroy(mpv)
      Unmanaged<MpvWakeupCallbackContext>.fromOpaque(wakeupContext).release()
      return false
    }
    lifecycleState.mpv = mpv
    lifecycleState.wakeupCallbackContext = wakeupContext
    mpv_set_wakeup_callback(
      mpv,
      { context in
        guard let context else { return }
        Unmanaged<MpvWakeupCallbackContext>.fromOpaque(context)
          .takeUnretainedValue()
          .dispatchWakeup()
      },
      wakeupContext
    )
    lifecycleLock.unlock()
    return true
  }

  func setLogLevel(_ level: String) {
    _ = withActiveMpv { mpv in
      mpv_request_log_messages(mpv, level)
    }
  }

  func setProperty(_ name: String, value: String) {
    setPropertyAsync(name, value: value) { _ in }
  }

  func setPropertyAsync(
    _ name: String,
    value: String,
    completion: @escaping (Result<Void, Error>) -> Void
  ) {
    guard isLifecycleActive else {
      completeOnMain { completion(.failure(self.lifecycleUnavailableError())) }
      return
    }
    #if targetEnvironment(simulator)
      if name == "hwdec" {
        if value != "no" {
          MpvLog.debug("[MpvPlayerCore] Simulator does not support hardware decoding; forcing hwdec=no")
        }
        setRawStringPropertyAsync(name, value: "no", completion: completion)
        return
      }
    #endif

    if isManagedRendererProperty(name) {
      MpvLog.debug("[MpvPlayerCore] Ignoring managed renderer property: \(name)=\(value)")
      completeOnMain { completion(.success(())) }
      return
    }

    updateVideoGravityIfNeeded(name: name, value: value)

    if name == "pause" {
      let paused = parseBoolProperty(value)
      let intent = beginCachedPauseIntent(paused)
      setRawStringPropertyAsync(name, value: value) { [weak self] result in
        self?.finishCachedPauseIntent(intent, result: result)
        completion(result)
      }
      return
    }

    if name == "hdr-enabled" {
      let enabled = value == "yes" || value == "true" || value == "1"
      setHDREnabled(enabled, completion: completion)
      return
    }

    if name == "dv-conversion-mode" {
      setDvConversionMode(value)
      completeOnMain { completion(.success(())) }
      return
    }

    if name == "dv-conversion-log" {
      setDvConversionLogEnabled(parseBoolProperty(value))
      completeOnMain { completion(.success(())) }
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
      MpvLog.debug("[MpvPlayerCore] DV conversion mode: \(normalized)")
    }
  }

  func setDvConversionLogEnabled(_ enabled: Bool) {
    cacheLock.lock()
    cachedDvConversionLogEnabled = enabled
    let mode = cachedDvConversionMode
    cacheLock.unlock()

    applyDvConversionModeEnvironment()
    if enabled {
      MpvLog.debug("[MpvPlayerCore] DV conversion logging enabled (mode: \(mode))")
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
    var propertyValue = value
    submitAsyncRequest(.void(completion)) { mpv, requestId in
      name.withCString { namePointer in
        mpv_set_property_async(mpv, requestId, namePointer, MPV_FORMAT_INT64, &propertyValue)
      }
    }
  }

  func setHDREnabled(_ enabled: Bool, completion: ((Result<Void, Error>) -> Void)? = nil) {
    cacheLock.lock()
    cachedHDREnabled = enabled
    let sigPeak = cachedLastSigPeak
    cacheLock.unlock()

    MpvLog.debug("[MpvPlayerCore] HDR enabled: \(enabled)")

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
      scheduleDisplayCriteriaUpdate()
    #endif
  }

  /// PiP presents the AVSampleBufferDisplayLayer directly, so subtitles must
  /// be composited into the video samples instead of the inline OSD layer.
  func setPipSubtitleCompositing(_ enabled: Bool) {
    #if os(iOS)
      let value = enabled ? "yes" : "no"
      setRawStringPropertyAsync("avfoundation-pip-composite-osd", value: value) { result in
        if case .failure(let error) = result {
          MpvLog.debug(
            "[MpvPlayerCore] Failed to set PiP subtitle compositing "
              + "to \(value): \(error.localizedDescription)"
          )
        }
      }
    #endif
  }

  func getPropertyAsync(_ name: String, completion: @escaping (Result<String?, Error>) -> Void) {
    guard isLifecycleActive else {
      completeOnMain { completion(.failure(self.lifecycleUnavailableError())) }
      return
    }
    if name == "dv-conversion-mode" {
      completeOnMain { completion(.success(self.getDvConversionMode())) }
      return
    }

    if name == "dv-conversion-log" {
      completeOnMain { completion(.success(self.getDvConversionLogEnabled() ? "yes" : "no")) }
      return
    }

    submitAsyncRequest(.getProperty(completion)) { mpv, requestId in
      name.withCString { namePointer in
        mpv_get_property_async(mpv, requestId, namePointer, MPV_FORMAT_STRING)
      }
    }
  }

  func observeProperty(_ name: String, format: String) {
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

    _ = withActiveMpv { mpv in
      mpv_observe_property(mpv, 0, name, mpvFormat)
    }
  }

  func command(_ args: [String]) {
    commandAsync(args) { _ in }
  }

  /// Runs an mpv command. `loadfile` completes with the id of the playlist
  /// entry it created — the `sourceId` of that source's start-file,
  /// playback-restart and end-file events — so a caller can bind the load to
  /// its source; every other command completes with nil.
  func commandAsync(_ args: [String], completion: @escaping (Result<Int64?, Error>) -> Void) {
    guard !args.isEmpty else {
      completeOnMain { completion(.success(nil)) }
      return
    }

    var cargs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
    cargs.append(nil)

    submitAsyncRequest(.command(completion)) { mpv, requestId in
      cargs.withUnsafeBufferPointer { buffer in
        var constPointers = buffer.map { UnsafePointer($0) }
        return mpv_command_async(mpv, requestId, &constPointers)
      }
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
    submitAsyncRequest(.void(completion)) { mpv, requestId in
      name.withCString { namePointer in
        value.withCString { valuePointer in
          var propertyValue: UnsafePointer<CChar>? = valuePointer
          return mpv_set_property_async(mpv, requestId, namePointer, MPV_FORMAT_STRING, &propertyValue)
        }
      }
    }
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
    cancelPendingRequests()

    cacheLock.lock()
    displayCriteriaHeld = true
    cachedDoviProfile = 0
    cachedDoviLevel = 0
    cachedContainerFps = 0
    cachedLastSigPeak = 0
    cachedVideoGamma = nil
    cachedVideoPrimaries = nil
    cachedVideoColorMatrix = nil
    cachedDeinterlaceActive = false
    cachedEstimatedFps = 0
    cacheLock.unlock()

    lifecycleLock.lock()
    lifecycleState.isTerminal = true
    let mpvHandle = lifecycleState.mpv
    let callbackContext = lifecycleState.wakeupCallbackContext
    lifecycleState.mpv = nil
    lifecycleState.wakeupCallbackContext = nil
    lifecycleLock.unlock()
    if let callbackContext {
      Unmanaged<MpvWakeupCallbackContext>.fromOpaque(callbackContext)
        .takeUnretainedValue()
        .detach()
    }

    let destroy = {
      if let mpvHandle {
        mpv_set_wakeup_callback(mpvHandle, nil, nil)
        mpv_terminate_destroy(mpvHandle)
      }
      if let callbackContext {
        Unmanaged<MpvWakeupCallbackContext>.fromOpaque(callbackContext).release()
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

  private func applySharedMpvOptions(mpv: OpaquePointer) {
    #if os(macOS)
      checkError(mpv_set_option_string(mpv, "vo", "gpu-next"))
      checkError(mpv_set_option_string(mpv, "gpu-api", "vulkan"))
      checkError(mpv_set_option_string(mpv, "gpu-context", "moltenvk"))
      checkError(mpv_set_option_string(mpv, "hwdec", "videotoolbox"))
      // The moltenvk context reports the screen as BT.2020 PQ once the layer
      // carries an EDR headroom above 1 (MpvPlayerCore.publishDisplayHeadroom);
      // that report is what lets the `auto` hint below engage at all. `source`
      // hands HDR sources through as PQ/HLG with their own mastering metadata
      // for WindowServer to map, the way AVFoundation does (#2393), and keeps
      // SDR sources SDR: on such a screen libplacebo negotiates a Display P3
      // BT.1886 surface for them, so they come out colour-managed instead of
      // on the untagged pass-through surface an SDR screen keeps. The default
      // `target` mode would re-encode SDR to PQ at 203 nits - where macOS then
      // places that against SDR white is unmeasured - and have mpv tone-map to
      // a display peak the context does not report.
      checkError(mpv_set_option_string(mpv, "target-colorspace-hint-mode", "source"))
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
        // Host-clock presentation: samples carry mpv's scheduled display
        // time against a free-running timebase, so audio-clock drift never
        // accumulates in the VO (#1776). Media-time presentation is only
        // needed for PiP, which tvOS does not have.
        checkError(mpv_set_option_string(mpv, "avfoundation-presentation", "host"))
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

  private func completeOnMain(_ completion: @escaping () -> Void) {
    if Thread.isMainThread {
      completion()
    } else {
      DispatchQueue.main.async(execute: completion)
    }
  }

  private func cancelPendingRequests() {
    pendingRequestsLock.lock()
    let pending = pendingRequests
    pendingRequests.removeAll()
    pendingRequestsLock.unlock()

    let error = MpvLifecycleUnavailableError("Player disposed")
    for (_, request) in pending {
      DispatchQueue.main.async {
        request.fail(with: error)
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

  private func lifecycleUnavailableError() -> MpvLifecycleUnavailableError {
    MpvLifecycleUnavailableError("Player is not initialized or has been disposed")
  }

  private func mpvError(_ status: CInt) -> NSError {
    NSError(
      domain: "mpv",
      code: Int(status),
      userInfo: [NSLocalizedDescriptionKey: safeString(mpv_error_string(status))]
    )
  }

  private func submitAsyncRequest(
    _ request: PendingRequest,
    submission: (OpaquePointer, UInt64) -> CInt
  ) {
    var requestId: UInt64?
    guard
      let status = withActiveMpv({ mpv in
        let id = registerRequest(request)
        requestId = id
        return submission(mpv, id)
      }),
      let requestId
    else {
      let error = lifecycleUnavailableError()
      completeOnMain {
        request.fail(with: error)
      }
      return
    }
    completeRequestIfSubmissionFailed(requestId: requestId, status: status)
  }

  private func completeRequestIfSubmissionFailed(requestId: UInt64, status: CInt) {
    guard status < 0, let request = takeRequest(requestId) else { return }
    let error = mpvError(status)
    DispatchQueue.main.async {
      request.fail(with: error)
    }
  }

  private func completeVoidRequest(requestId: UInt64, error status: CInt) {
    guard case .void(let completion) = takeRequest(requestId) else { return }
    let result: Result<Void, Error> =
      status < 0 ? .failure(mpvError(status)) : .success(())
    DispatchQueue.main.async {
      completion(result)
    }
  }

  private func completeCommandRequest(_ event: mpv_event) {
    guard case .command(let completion) = takeRequest(event.reply_userdata) else { return }

    if event.error < 0 {
      let error = mpvError(event.error)
      DispatchQueue.main.async {
        completion(.failure(error))
      }
      return
    }

    // The result node belongs to the event: read it here, on the event queue.
    var playlistEntryId: Int64?
    if let commandPointer = event.data?.assumingMemoryBound(to: mpv_event_command.self) {
      playlistEntryId = Self.playlistEntryId(in: commandPointer.pointee.result)
    }
    DispatchQueue.main.async {
      completion(.success(playlistEntryId))
    }
  }

  /// The `playlist_entry_id` of a `loadfile` result map; nil for any other
  /// command result.
  private static func playlistEntryId(in result: mpv_node) -> Int64? {
    guard result.format == MPV_FORMAT_NODE_MAP, let list = result.u.list else { return nil }
    let map = list.pointee
    guard map.num > 0, let keys = map.keys, let values = map.values else { return nil }
    for index in 0..<Int(map.num) {
      guard let key = keys[index], strcmp(key, "playlist_entry_id") == 0 else { continue }
      let value = values[index]
      return value.format == MPV_FORMAT_INT64 ? value.u.int64 : nil
    }
    return nil
  }

  private func completeGetPropertyRequest(_ event: mpv_event) {
    guard case .getProperty(let completion) = takeRequest(event.reply_userdata) else { return }

    if event.error < 0 {
      let error = mpvError(event.error)
      DispatchQueue.main.async {
        completion(.failure(error))
      }
      return
    }

    var value: String?
    if let propertyPointer = event.data?.assumingMemoryBound(to: mpv_event_property.self) {
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

  fileprivate func readEventsFromCallback() {
    queue.async { [weak self] in
      guard let self else { return }

      while let mpv = self.withActiveMpv({ $0 }) {
        let event = mpv_wait_event(mpv, 0)
        guard let event else { break }

        if event.pointee.event_id == MPV_EVENT_NONE {
          break
        }

        self.handleEvent(event.pointee)
      }
    }
  }

  func dispatchDelegateEvent(name: String, data: [String: Any]?, sourceId: Int64? = nil) {
    var sourcedData = data
    if let sourceId {
      if sourcedData == nil { sourcedData = [:] }
      sourcedData?["sourceId"] = sourceId
    }
    let eventData = sourcedData
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isLifecycleActive else { return }
      self.delegate?.onEvent(name: name, data: eventData)
    }
  }

  func dispatchDelegateProperty(name: String, value: Any?, sourceId: Int64?) {
    DispatchQueue.main.async { [weak self] in
      guard let self, self.isLifecycleActive else { return }
      self.delegate?.onPropertyChange(name: name, value: value, sourceId: sourceId)
    }
  }

  private func handleEvent(_ event: mpv_event) {
    switch event.event_id {
    case MPV_EVENT_PROPERTY_CHANGE:
      guard let data = event.data else { break }
      let property = data.assumingMemoryBound(to: mpv_event_property.self).pointee
      let name = safeString(property.name)
      handlePropertyChange(
        name: name,
        property: property,
        replyUserdata: event.reply_userdata,
        sourceId: activeSourceId
      )

    case MPV_EVENT_COMMAND_REPLY:
      completeCommandRequest(event)

    case MPV_EVENT_SET_PROPERTY_REPLY:
      completeVoidRequest(requestId: event.reply_userdata, error: event.error)

    case MPV_EVENT_GET_PROPERTY_REPLY:
      completeGetPropertyRequest(event)

    case MPV_EVENT_START_FILE:
      cacheLock.lock()
      cachedEstimatedFps = 0
      displayCriteriaHeld = true
      cacheLock.unlock()
      if let startFilePtr = event.data?.assumingMemoryBound(to: mpv_event_start_file.self) {
        let sourceId = startFilePtr.pointee.playlist_entry_id
        activeSourceId = sourceId
        dispatchDelegateEvent(name: "start-file", data: nil, sourceId: sourceId)
      } else {
        activeSourceId = nil
        dispatchDelegateEvent(name: "start-file", data: nil)
      }

    case MPV_EVENT_FILE_LOADED:
      dispatchDelegateEvent(name: "file-loaded", data: nil, sourceId: activeSourceId)

    case MPV_EVENT_END_FILE:
      // Queued after the video chain is torn down but before this client can
      // receive any teardown-valued property change, so the hold is in place
      // before those deliveries could commit a partial snapshot.
      cacheLock.lock()
      displayCriteriaHeld = true
      cacheLock.unlock()
      if let endFilePtr = event.data?.assumingMemoryBound(to: mpv_event_end_file.self) {
        let endFile = endFilePtr.pointee
        var data: [String: Any] = ["reason": Int(endFile.reason.rawValue)]
        if endFile.reason == MPV_END_FILE_REASON_ERROR {
          data["error"] = Int(endFile.error)
          data["message"] = safeString(mpv_error_string(endFile.error))
        }
        dispatchDelegateEvent(
          name: "end-file",
          data: data,
          sourceId: endFile.playlist_entry_id
        )
      } else {
        dispatchDelegateEvent(name: "end-file", data: nil)
      }

    case MPV_EVENT_SHUTDOWN:
      MpvLog.debug("[MpvPlayerCore] MPV shutdown event")

    case MPV_EVENT_PLAYBACK_RESTART:
      // The first shown frame after a load or seek: the moment the presented
      // cadence is known (mpv decodes two frames before showing one).
      // `estimated-vf-fps` changes every frame, so it is read here instead
      // of observed. Every other display-criteria input is read with it and
      // taken as authoritative — unavailable means the stream lacks it. mpv
      // delivers queued events before pending property changes and replaces
      // an undelivered value with a later read, so the observer caches can
      // hold the previous file's values or its teardown nils here; criteria
      // built from that mix would start one mode switch and then another,
      // or clear and re-set the mode already on the link. This snapshot
      // releases `displayCriteriaHeld`, making it the file's first commit;
      // scheduling it before the delegate dispatch keeps it ahead of the
      // `playback-restart` Dart gates its mode-switch wait on.
      let estimatedFps = readDoubleProperty("estimated-vf-fps") ?? 0
      let containerFps = readDoubleProperty("container-fps") ?? 0
      let deinterlaceActive = readFlagProperty("deinterlace-active") ?? false
      let videoParams = readMapProperty("video-params") ?? [:]
      let videoTrack = readMapProperty("current-tracks/video") ?? [:]
      cacheLock.lock()
      cachedEstimatedFps = estimatedFps
      cachedContainerFps = containerFps
      cachedDeinterlaceActive = deinterlaceActive
      cachedWidth = Double((videoParams["w"] as? Int64) ?? 0)
      cachedHeight = Double((videoParams["h"] as? Int64) ?? 0)
      cachedLastSigPeak = (videoParams["sig-peak"] as? Double) ?? 0
      cachedVideoGamma = videoParams["gamma"] as? String
      cachedVideoPrimaries = videoParams["primaries"] as? String
      cachedVideoColorMatrix = videoParams["colormatrix"] as? String
      cachedDoviProfile = (videoTrack["dolby-vision-profile"] as? Int64) ?? 0
      cachedDoviLevel = (videoTrack["dolby-vision-level"] as? Int64) ?? 0
      displayCriteriaHeld = false
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
      var data: [String: Any]?
      if let position = readDoubleProperty("time-pos") {
        data = ["positionSeconds": position]
      }
      dispatchDelegateEvent(
        name: "playback-restart",
        data: data,
        sourceId: activeSourceId
      )

    case MPV_EVENT_LOG_MESSAGE:
      if isLifecycleBackgrounded { break }
      if let messagePointer = event.data?.assumingMemoryBound(to: mpv_event_log_message.self) {
        let message = messagePointer.pointee
        let prefix = message.prefix.map { safeString($0) } ?? ""
        let level = message.level.map { safeString($0) } ?? ""
        let text = message.text.map { safeString($0) } ?? ""

        dispatchDelegateEvent(
          name: "log-message",
          data: ["prefix": prefix, "level": level, "text": text]
        )
      }

    default:
      break
    }
  }

  /// Synchronous double read for PLAYBACK_RESTART. `mpv_get_property` round-trips
  /// through the core, which on iOS/tvOS can be blocked behind the avfoundation VO
  /// waiting on the main thread; the main thread in turn takes `lifecycleLock` in
  /// `isLifecycleActive`. Snapshot the handle under the lock, then query without it.
  /// Must run on `queue`: destruction is serialized on the same queue, so the handle
  /// cannot be torn down between the snapshot and the read.
  private func readDoubleProperty(_ name: String) -> Double? {
    dispatchPrecondition(condition: .onQueue(queue))
    guard let mpv = withActiveMpv({ $0 }) else { return nil }
    var value = 0.0
    let status = mpv_get_property(mpv, name, MPV_FORMAT_DOUBLE, &value)
    guard status >= 0, value.isFinite else { return nil }
    return value
  }

  /// Synchronous flag read for PLAYBACK_RESTART; same constraints as
  /// `readDoubleProperty`. Nil when the property is unavailable.
  private func readFlagProperty(_ name: String) -> Bool? {
    dispatchPrecondition(condition: .onQueue(queue))
    guard let mpv = withActiveMpv({ $0 }) else { return nil }
    var value: Int32 = 0
    let status = mpv_get_property(mpv, name, MPV_FORMAT_FLAG, &value)
    guard status >= 0 else { return nil }
    return value != 0
  }

  /// Synchronous node-map read for PLAYBACK_RESTART; same constraints as
  /// `readDoubleProperty`. Nil when the property is unavailable. One read of
  /// `video-params` or a track entry replaces a core round-trip per field.
  private func readMapProperty(_ name: String) -> [String: Any]? {
    dispatchPrecondition(condition: .onQueue(queue))
    guard let mpv = withActiveMpv({ $0 }) else { return nil }
    var node = mpv_node()
    let status = mpv_get_property(mpv, name, MPV_FORMAT_NODE, &node)
    guard status >= 0 else { return nil }
    defer { mpv_free_node_contents(&node) }
    return convertNode(node) as? [String: Any]
  }

  private func handlePropertyChange(
    name: String,
    property: mpv_event_property,
    replyUserdata: UInt64,
    sourceId: Int64?
  ) {
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

    // Display-criteria caches take only available values from observers. An
    // unavailable delivery is ambiguous — the file being torn down, a stale
    // read superseded before delivery, or genuinely absent — and only the
    // synchronous PLAYBACK_RESTART snapshot can tell; it writes the defaults
    // itself. Committing on nil here is what cleared the link between two
    // files of the same mode.
    switch name {
    case "current-tracks/video/dolby-vision-profile":
      guard let profile = value as? Int64 else { break }
      cacheLock.lock()
      cachedDoviProfile = profile
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "current-tracks/video/dolby-vision-level":
      guard let level = value as? Int64 else { break }
      cacheLock.lock()
      cachedDoviLevel = level
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "container-fps":
      guard let fps = value as? Double else { break }
      cacheLock.lock()
      cachedContainerFps = fps
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "deinterlace-active":
      guard let active = value as? Bool else { break }
      cacheLock.lock()
      cachedDeinterlaceActive = active
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/gamma":
      guard let gamma = value as? String else { break }
      cacheLock.lock()
      cachedVideoGamma = gamma
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/primaries":
      guard let primaries = value as? String else { break }
      cacheLock.lock()
      cachedVideoPrimaries = primaries
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "video-params/colormatrix":
      guard let colorMatrix = value as? String else { break }
      cacheLock.lock()
      cachedVideoColorMatrix = colorMatrix
      cacheLock.unlock()
      scheduleDisplayCriteriaUpdate()
    case "width", "height":
      if value != nil { scheduleDisplayCriteriaUpdate() }
    default:
      break
    }

    if Self.internalObserverIds.contains(replyUserdata) { return }
    if isLifecycleBackgrounded && !Self.criticalProperties.contains(name) {
      backgroundedPropertyChanges[name] = (value: value, sourceId: sourceId)
      return
    }

    backgroundedPropertyChanges.removeValue(forKey: name)
    dispatchDelegateProperty(name: name, value: value, sourceId: sourceId)
  }

  private func updateCachedProperty(name: String, value: Any?) {
    cacheLock.lock()
    defer { cacheLock.unlock() }

    switch name {
    case "pause":
      if let paused = value as? Bool {
        pauseObservationRevision &+= 1
        confirmedPaused = paused
        if pendingPauseIntents.isEmpty { cachedPaused = paused }
      }
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

  #if DEBUG
    func observeCachedPauseForTesting(_ paused: Bool) {
      updateCachedProperty(name: "pause", value: paused)
    }
  #endif

  private func retirePauseIntents(through generation: UInt64) {
    pendingPauseIntents = pendingPauseIntents.filter { $0.key > generation }
  }

  func beginCachedPauseIntent(
    _ paused: Bool
  ) -> (generation: UInt64, observationRevision: UInt64, paused: Bool) {
    cacheLock.lock()
    pauseIntentGeneration &+= 1
    let intent = (
      generation: pauseIntentGeneration,
      observationRevision: pauseObservationRevision,
      paused: paused
    )
    pendingPauseIntents[intent.generation] = paused
    cachedPaused = paused
    cacheLock.unlock()
    return intent
  }

  func finishCachedPauseIntent(
    _ intent: (generation: UInt64, observationRevision: UInt64, paused: Bool),
    result: Result<Void, Error>
  ) {
    cacheLock.lock()
    pendingPauseIntents.removeValue(forKey: intent.generation)
    if intent.generation >= resolvedPauseGeneration {
      resolvedPauseGeneration = intent.generation
      if case .success = result,
        intent.observationRevision == pauseObservationRevision
      {
        confirmedPaused = intent.paused
      }
      retirePauseIntents(through: intent.generation)
    }
    if let latest = pendingPauseIntents.lazy
      .filter({ $0.key > self.resolvedPauseGeneration })
      .max(by: { $0.key < $1.key })
    {
      cachedPaused = latest.value
    } else {
      cachedPaused = confirmedPaused
    }
    cacheLock.unlock()
  }

  private static let maximumNodeDepth = 32
  private static let maximumNodeEntries = 4_096
  private static let maximumNodeByteCount = 16 * 1_024 * 1_024
  private static let maximumSideDataDimension: Int64 = 16_384
  private static let maximumSideDataPixels: Int64 = 64 * 1_024 * 1_024

  private struct NodeConversionBudget {
    var remainingEntries = MpvPlayerCoreBase.maximumNodeEntries
    var remainingBytes = MpvPlayerCoreBase.maximumNodeByteCount
  }

  func convertNode(_ node: mpv_node) -> Any? {
    var budget = NodeConversionBudget()
    return convertNode(node, depth: 0, budget: &budget)
  }

  func validateSideDataDimensions(width: Int64, height: Int64) -> Bool {
    guard width > 0, height > 0,
      width <= Self.maximumSideDataDimension,
      height <= Self.maximumSideDataDimension
    else { return false }
    let (pixels, overflow) = width.multipliedReportingOverflow(by: height)
    return !overflow && pixels <= Self.maximumSideDataPixels
  }

  private func dimensionValue(_ node: mpv_node) -> Int64? {
    switch node.format {
    case MPV_FORMAT_INT64:
      return node.u.int64
    case MPV_FORMAT_DOUBLE:
      let value = node.u.double_
      guard value.isFinite, value.rounded() == value,
        value >= Double(Int64.min), value <= Double(Int64.max)
      else { return nil }
      return Int64(value)
    default:
      return nil
    }
  }

  private func convertNodeString(
    _ pointer: UnsafePointer<CChar>,
    budget: inout NodeConversionBudget
  ) -> String? {
    let length = strnlen(pointer, budget.remainingBytes + 1)
    guard length <= budget.remainingBytes else { return nil }
    budget.remainingBytes -= length
    if let string = String(validatingUTF8: pointer) {
      return string
    }
    let bytes = UnsafeBufferPointer(
      start: UnsafeRawPointer(pointer).assumingMemoryBound(to: UInt8.self),
      count: length
    )
    return String(bytes.map { Character(Unicode.Scalar($0)) })
  }

  private func hasValidSideDataDimensions(_ list: mpv_node_list, count: Int) -> Bool {
    var hasByteArray = false
    var widthNode: mpv_node?
    var heightNode: mpv_node?
    for index in 0..<count {
      let value = list.values[index]
      hasByteArray = hasByteArray || value.format == MPV_FORMAT_BYTE_ARRAY
      guard let keyPointer = list.keys[index] else { continue }
      if strcmp(keyPointer, "width") == 0 || strcmp(keyPointer, "w") == 0 {
        widthNode = value
      } else if strcmp(keyPointer, "height") == 0 || strcmp(keyPointer, "h") == 0 {
        heightNode = value
      }
    }
    guard hasByteArray, widthNode != nil || heightNode != nil else { return true }
    guard let widthNode, let heightNode,
      let width = dimensionValue(widthNode),
      let height = dimensionValue(heightNode)
    else { return false }
    return validateSideDataDimensions(width: width, height: height)
  }

  private func convertNode(
    _ node: mpv_node,
    depth: Int,
    budget: inout NodeConversionBudget
  ) -> Any? {
    guard depth <= Self.maximumNodeDepth, budget.remainingEntries > 0 else { return nil }
    budget.remainingEntries -= 1

    switch node.format {
    case MPV_FORMAT_STRING:
      guard let string = node.u.string else { return nil }
      return convertNodeString(string, budget: &budget)

    case MPV_FORMAT_FLAG:
      return node.u.flag != 0

    case MPV_FORMAT_INT64:
      return node.u.int64

    case MPV_FORMAT_DOUBLE:
      return node.u.double_

    case MPV_FORMAT_BYTE_ARRAY:
      guard let byteArray = node.u.ba?.pointee else { return nil }
      let byteCount = byteArray.size
      guard byteCount <= budget.remainingBytes else { return nil }
      guard byteCount == 0 || byteArray.data != nil else { return nil }
      budget.remainingBytes -= byteCount
      guard byteCount > 0, let data = byteArray.data else { return Data() }
      return Data(bytes: data, count: byteCount)

    case MPV_FORMAT_NODE_ARRAY:
      guard let list = node.u.list?.pointee else { return nil }
      let count = Int(list.num)
      guard list.num >= 0, count <= budget.remainingEntries else { return nil }
      guard count == 0 || list.values != nil else { return nil }
      var array = [Any]()
      array.reserveCapacity(count)
      for index in 0..<count {
        if let item = convertNode(list.values[index], depth: depth + 1, budget: &budget) {
          array.append(item)
        }
      }
      return array

    case MPV_FORMAT_NODE_MAP:
      guard let list = node.u.list?.pointee else { return nil }
      let count = Int(list.num)
      guard list.num >= 0, count <= budget.remainingEntries else { return nil }
      guard count == 0 || (list.values != nil && list.keys != nil) else { return nil }
      guard hasValidSideDataDimensions(list, count: count) else { return nil }
      var dictionary = [String: Any]()
      dictionary.reserveCapacity(count)
      for index in 0..<count {
        if let keyPointer = list.keys[index],
          let key = convertNodeString(keyPointer, budget: &budget),
          let value = convertNode(list.values[index], depth: depth + 1, budget: &budget)
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
      MpvLog.error("[MpvPlayerCore] MPV error: \(safeString(mpv_error_string(status)))")
    }
  }
}
