import AVFoundation
#if os(tvOS)
  import AVKit
#endif
import QuartzCore
import UIKit

/// Core MPV player using AVFoundation sample-buffer rendering for iOS/tvOS.
class MpvPlayerCore: MpvPlayerCoreBase {

  private var containerView: UIView?
  private weak var window: UIWindow?
  private var mainBlankView: UIView?
  private var isVisible = false
  private var isDisposed = false
  private var activeDisplayCriteriaKey: String?

  var isPipStarting = false

  func initialize(in window: UIWindow) -> Bool {
    guard !isInitialized else {
      print("[MpvPlayerCore] Already initialized")
      return true
    }

    self.window = window

    let container = UIView(frame: window.bounds)
    container.backgroundColor = .black
    container.isUserInteractionEnabled = false

    let layer = MpvVideoLayer()
    layer.frame = container.bounds
    layer.contentsScale = window.screen.nativeScale
    layer.isOpaque = true
    layer.backgroundColor = UIColor.black.cgColor
    layer.videoGravity = .resizeAspect

    container.layer.addSublayer(layer)
    containerView = container
    videoLayer = layer

    window.insertSubview(container, at: 0)

    guard setupMpv() else {
      print("[MpvPlayerCore] Failed to setup MPV")
      layer.removeFromSuperlayer()
      container.removeFromSuperview()
      videoLayer = nil
      containerView = nil
      return false
    }

    setupNotifications()
    #if os(iOS)
      ExternalDisplayManager.shared.attach(core: self)
    #endif

    isInitialized = true
    print("[MpvPlayerCore] Initialized successfully with MPV")
    return true
  }

  var sampleBufferDisplayLayer: MpvVideoLayer? { videoLayer }

  func setVisible(_ visible: Bool) {
    guard containerView != nil else { return }

    isVisible = visible
    if visible { refreshExternalDisplayAttachment() }
    setContainerHidden(!visible)
    if !visible { mainBlankView?.isHidden = true }
  }

  func updateFrame(_ frame: CGRect? = nil) {
    guard let videoLayer, let containerView else { return }

    withoutLayerAnimations {
      if let frame {
        containerView.frame = frame
        videoLayer.frame = containerView.bounds
      } else if let superview = containerView.superview {
        containerView.frame = superview.bounds
        videoLayer.frame = containerView.bounds
      } else if let window {
        containerView.frame = window.bounds
        videoLayer.frame = containerView.bounds
      }

      mainBlankView?.frame = window?.bounds ?? .zero

      let screen = containerView.window?.screen ?? window?.screen ?? UIScreen.main
      let scale = screen.nativeScale > 0 ? screen.nativeScale : screen.scale
      videoLayer.contentsScale = scale
    }

    #if os(iOS)
      updateEDRMode(sigPeak: lastSigPeak)
    #endif
  }

  func externalDisplayDidChange() {
    refreshExternalDisplayAttachment()
  }

  private func refreshExternalDisplayAttachment() {
    guard containerView != nil else { return }

    let externalSuperview = externalVideoSuperview

    if let externalSuperview {
      moveContainerView(to: externalSuperview)
      setMainBlankViewVisible(true)
    } else if isVisible, let window {
      moveContainerView(to: window)
      setMainBlankViewVisible(false)
    } else {
      setMainBlankViewVisible(false)
    }

    setContainerHidden(!isVisible)
    updateFrame()
  }

  private var externalVideoSuperview: UIView? {
    #if os(iOS)
      isVisible && !isPipActive && !isPipStarting
        ? ExternalDisplayManager.shared.videoSuperview
        : nil
    #else
      nil
    #endif
  }

  private func moveContainerView(to superview: UIView) {
    guard let containerView else { return }

    withoutLayerAnimations {
      if containerView.superview !== superview {
        containerView.removeFromSuperview()
        superview.insertSubview(containerView, at: 0)
      } else if superview.subviews.first !== containerView {
        superview.insertSubview(containerView, at: 0)
      }

      containerView.frame = superview.bounds
      containerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
  }

  private func setMainBlankViewVisible(_ visible: Bool) {
    guard visible, let window else {
      mainBlankView?.removeFromSuperview()
      mainBlankView = nil
      return
    }

    let blankView = mainBlankView ?? UIView(frame: window.bounds)
    withoutLayerAnimations {
      blankView.backgroundColor = .black
      blankView.isUserInteractionEnabled = false
      blankView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      blankView.frame = window.bounds

      if blankView.superview !== window {
        blankView.removeFromSuperview()
        window.insertSubview(blankView, at: 0)
      } else if window.subviews.first !== blankView {
        window.insertSubview(blankView, at: 0)
      }

      blankView.isHidden = false
    }
    mainBlankView = blankView
  }

  private func setContainerHidden(_ hidden: Bool) {
    withoutLayerAnimations {
      containerView?.isHidden = hidden
    }
  }

  private func withoutLayerAnimations(_ updates: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    updates()
    CATransaction.commit()
  }

  /// Nudge mpv to present the current paused frame after leaving PiP.
  func forceDraw() {
    command(["seek", "0", "relative+exact"])
  }

  private func restoreVideoPresentation() {
    guard !isPipActive else { return }

    refreshExternalDisplayAttachment()
    recoverDisplayLayerIfNeeded()
    updateEDRMode(sigPeak: lastSigPeak)
    if isPaused { forceDraw() }
  }

  private func recoverDisplayLayerIfNeeded() {
    guard let videoLayer else { return }

    var requiresFlush = false
    if #available(iOS 14.0, tvOS 14.0, *) {
      requiresFlush = videoLayer.requiresFlushToResumeDecoding
    }
    let status = videoLayer.status
    guard requiresFlush || status == .failed else { return }

    videoLayer.flush()
  }

  override func updateEDRMode(sigPeak: Double) {
    #if os(iOS)
      guard let videoLayer else { return }

      let shouldEnableEDR = hdrEnabled && sigPeak > 1.0
      if #available(iOS 26.0, *) {
        withoutLayerAnimations {
          videoLayer.preferredDynamicRange = shouldEnableEDR ? .high : .standard
        }
      } else if #available(iOS 17.0, *) {
        withoutLayerAnimations {
          videoLayer.wantsExtendedDynamicRangeContent = shouldEnableEDR
        }
      }
    #endif
  }

  @discardableResult
  override func updateDisplayCriteria(
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
  ) -> Bool {
    #if os(tvOS)
      guard let window = containerView?.window ?? self.window else { return false }
      let displayManager = window.avDisplayManager

      if width <= 0 || height <= 0 {
        clearDisplayCriteria(displayManager, reason: "no video dimensions")
        return false
      }

      let refreshRate = Float(fps > 0 ? fps : 0)
      let sourceHasDolbyVision = doviProfile > 0
      guard sourceHasDolbyVision || sigPeak > 0 || gamma != nil || primaries != nil || colorMatrix != nil else {
        clearDisplayCriteria(displayManager, reason: "no display metadata")
        return false
      }

      let sourceBaseRange = Self.resolveBaseDisplayDynamicRange(
        sigPeak: sigPeak,
        gamma: gamma,
        primaries: primaries,
        colorMatrix: colorMatrix,
        doviCompatibilityId: doviCompatibilityId
      )
      let sourceRange: DisplayDynamicRange = sourceHasDolbyVision ? .dolbyVision : sourceBaseRange
      var displayRange: DisplayDynamicRange =
        sourceHasDolbyVision
        ? .dolbyVision
        : Self.supportedDisplayDynamicRange(for: sourceBaseRange)
      guard displayManager.isDisplayCriteriaMatchingEnabled else {
        clearDisplayCriteria(displayManager, reason: "matching disabled")
        return false
      }
      guard #available(tvOS 17.0, *) else {
        clearDisplayCriteria(displayManager, reason: "display criteria unavailable")
        return false
      }

      var formatDescription = Self.makeDisplayFormatDescription(
        dynamicRange: displayRange,
        width: width,
        height: height,
        doviProfile: doviProfile,
        doviLevel: doviLevel,
        doviCompatibilityId: doviCompatibilityId)
      if formatDescription == nil, sourceHasDolbyVision {
        displayRange = sourceBaseRange
        formatDescription = Self.makeDisplayFormatDescription(
          dynamicRange: displayRange,
          width: width,
          height: height,
          doviProfile: doviProfile,
          doviLevel: doviLevel,
          doviCompatibilityId: doviCompatibilityId)
      }

      guard let formatDescription else {
        clearDisplayCriteria(displayManager, reason: "format description failed")
        return false
      }

      let criteriaKey =
        "\(displayRange.rawValue)|\(refreshRate)|\(width)x\(height)|\(doviProfile)|\(doviLevel)|\(doviCompatibilityId ?? -1)"
      if activeDisplayCriteriaKey == criteriaKey { return true }

      displayManager.preferredDisplayCriteria = AVDisplayCriteria(
        refreshRate: refreshRate,
        formatDescription: formatDescription
      )
      activeDisplayCriteriaKey = criteriaKey
      print(
        "[MpvPlayerCore] preferredDisplayCriteria set to \(displayRange.rawValue) (source: \(sourceRange.rawValue), fps: \(refreshRate), \(width)x\(height), DV profile: \(doviProfile), level: \(doviLevel), compat: \(doviCompatibilityId ?? -1))"
      )
      return true
    #else
      return false
    #endif
  }

  #if os(tvOS)
    private enum DisplayDynamicRange: String {
      case sdr = "SDR"
      case hdr10 = "HDR10"
      case hlg = "HLG"
      case dolbyVision = "Dolby Vision"
    }

    private func clearDisplayCriteria(_ displayManager: AVDisplayManager, reason: String) {
      if activeDisplayCriteriaKey != nil || displayManager.preferredDisplayCriteria != nil {
        displayManager.preferredDisplayCriteria = nil
        activeDisplayCriteriaKey = nil
        print("[MpvPlayerCore] preferredDisplayCriteria cleared (\(reason))")
      }
    }

    private static func resolveBaseDisplayDynamicRange(
      sigPeak: Double,
      gamma: String?,
      primaries: String?,
      colorMatrix: String?,
      doviCompatibilityId: Int64?
    ) -> DisplayDynamicRange {
      let normalizedGamma = normalizeColorTag(gamma)
      let normalizedPrimaries = normalizeColorTag(primaries)
      let normalizedColorMatrix = normalizeColorTag(colorMatrix)

      if normalizedGamma.contains("hlg") || normalizedGamma.contains("arib") {
        return .hlg
      }
      if normalizedGamma.contains("pq") || normalizedGamma.contains("smpte2084")
        || normalizedGamma.contains("st2084") || sigPeak > 1.0
        || normalizedPrimaries.contains("bt2020") || normalizedColorMatrix.contains("bt2020")
      {
        return .hdr10
      }
      switch doviCompatibilityId {
      case 1, 6:
        return .hdr10
      case 4:
        return .hlg
      case 2:
        return .sdr
      default:
        break
      }
      return .sdr
    }

    private static func normalizeColorTag(_ value: String?) -> String {
      value?.lowercased().filter { $0.isLetter || $0.isNumber } ?? ""
    }

    private static func supportedDisplayDynamicRange(for range: DisplayDynamicRange) -> DisplayDynamicRange {
      let availableModes = AVPlayer.availableHDRModes
      switch range {
      case .dolbyVision:
        if availableModes.contains(.dolbyVision) { return .dolbyVision }
        if availableModes.contains(.hdr10) { return .hdr10 }
        if availableModes.contains(.hlg) { return .hlg }
        return .sdr
      case .hdr10:
        return availableModes.contains(.hdr10) ? .hdr10 : .sdr
      case .hlg:
        return availableModes.contains(.hlg) ? .hlg : .sdr
      case .sdr:
        return .sdr
      }
    }

    private static func makeDisplayFormatDescription(
      dynamicRange: DisplayDynamicRange,
      width: Int32,
      height: Int32,
      doviProfile: Int64,
      doviLevel: Int64,
      doviCompatibilityId: Int64?
    ) -> CMVideoFormatDescription? {
      if dynamicRange == .dolbyVision {
        // Profile 8.x always carries a compatibility id; profile 5 has none.
        // We assume bl_signal_compatibility_id = 1 (HDR10 base) for profile 8
        // because mpv does not expose the compat id and that's by far the
        // most common case.
        let fallbackCompat: Int64 = doviProfile == 8 ? 1 : 0
        let compat = UInt8(truncatingIfNeeded: doviCompatibilityId ?? fallbackCompat)
        return makeDolbyVisionFormatDescription(
          width: width,
          height: height,
          profile: UInt8(truncatingIfNeeded: doviProfile),
          level: UInt8(truncatingIfNeeded: doviLevel),
          compatibility: compat
        )
      }

      let extensions: [CFString: Any]
      switch dynamicRange {
      case .hdr10:
        extensions = [
          kCMFormatDescriptionExtension_ColorPrimaries:
            kCMFormatDescriptionColorPrimaries_ITU_R_2020,
          kCMFormatDescriptionExtension_TransferFunction:
            kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
          kCMFormatDescriptionExtension_YCbCrMatrix:
            kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
        ]
      case .hlg:
        extensions = [
          kCMFormatDescriptionExtension_ColorPrimaries:
            kCMFormatDescriptionColorPrimaries_ITU_R_2020,
          kCMFormatDescriptionExtension_TransferFunction:
            kCMFormatDescriptionTransferFunction_ITU_R_2100_HLG,
          kCMFormatDescriptionExtension_YCbCrMatrix:
            kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
        ]
      case .sdr:
        extensions = [
          kCMFormatDescriptionExtension_ColorPrimaries:
            kCMFormatDescriptionColorPrimaries_ITU_R_709_2,
          kCMFormatDescriptionExtension_TransferFunction:
            kCMFormatDescriptionTransferFunction_ITU_R_709_2,
          kCMFormatDescriptionExtension_YCbCrMatrix:
            kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2,
        ]
      case .dolbyVision:
        return nil
      }

      var fd: CMVideoFormatDescription?
      let status = CMVideoFormatDescriptionCreate(
        allocator: kCFAllocatorDefault,
        codecType: kCMVideoCodecType_HEVC,
        width: width,
        height: height,
        extensions: extensions as CFDictionary,
        formatDescriptionOut: &fd
      )
      return status == noErr ? fd : nil
    }

    /// Build a synthetic 'dvh1' `CMVideoFormatDescription` from the Dolby Vision
    /// metadata mpv exposes. Used solely as a hint object for
    /// `AVDisplayCriteria(refreshRate:formatDescription:)` — it is never
    /// enqueued onto the sample-buffer layer.
    private static func makeDolbyVisionFormatDescription(
      width: Int32,
      height: Int32,
      profile: UInt8,
      level: UInt8,
      compatibility: UInt8
    ) -> CMVideoFormatDescription? {
      // 24-byte Dolby Vision configuration record (dvcC ≤ profile 7, dvvC ≥ 8).
      // Layout from ETSI TS 103 572 §7.1.1 — same packing as FFmpeg's
      // videotoolbox_dovi_extradata_create (in 0002 patch):
      //   [0]     dv_version_major (= 1)
      //   [1]     dv_version_minor (= 0)
      //   [2..3]  big-endian uint16: profile<<9 | level<<3 | rpu<<2 | el<<1 | bl
      //   [4]     compatibility<<4 | md_compression<<2
      //   [5..23] reserved zero
      var dovi = [UInt8](repeating: 0, count: 24)
      dovi[0] = 1
      dovi[1] = 0
      let flags: UInt16 =
        (UInt16(profile) & 0x7f) << 9
        | (UInt16(level) & 0x3f) << 3
        | (1 << 2)  // rpu_present_flag
        | (1 << 0)  // bl_present_flag
      dovi[2] = UInt8((flags >> 8) & 0xff)
      dovi[3] = UInt8(flags & 0xff)
      dovi[4] = (compatibility & 0x0f) << 4

      // CoreMedia carries codec-specific boxes under
      // kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms.
      let recordKey: CFString = (profile > 7 ? "dvvC" : "dvcC") as CFString
      let atoms: [CFString: Any] = [recordKey: Data(dovi) as CFData]

      let extensions: [CFString: Any] = [
        kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms: atoms as CFDictionary,
        kCMFormatDescriptionExtension_ColorPrimaries:
          kCMFormatDescriptionColorPrimaries_ITU_R_2020,
        kCMFormatDescriptionExtension_TransferFunction:
          kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
        kCMFormatDescriptionExtension_YCbCrMatrix:
          kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
      ]

      var fd: CMVideoFormatDescription?
      let status = CMVideoFormatDescriptionCreate(
        allocator: kCFAllocatorDefault,
        codecType: kCMVideoCodecType_DolbyVisionHEVC,  // 'dvh1'
        width: width,
        height: height,
        extensions: extensions as CFDictionary,
        formatDescriptionOut: &fd
      )
      return status == noErr ? fd : nil
    }
  #endif

  func dispose() {
    // Guard double-dispose: the plugin calls dispose() then drops the
    // strong ref, which fires deinit → dispose() again. The second call
    // would re-enter and crash on weak-ref formation during dealloc.
    guard !isDisposed else { return }
    isDisposed = true

    // Reset the HDMI mode hint synchronously while self is still alive
    // and on main. An async-to-main dispatch here would be drained after
    // dealloc (the plugin sets playerCore = nil right after this call
    // returns), leaving the link stuck at the last clip's refresh rate.
    updateDisplayCriteria(
      doviProfile: 0, doviLevel: 0, doviCompatibilityId: nil,
      fps: 0, width: 0, height: 0, sigPeak: 0,
      gamma: nil, primaries: nil, colorMatrix: nil)

    NotificationCenter.default.removeObserver(self)
    #if os(iOS)
      ExternalDisplayManager.shared.detach(core: self)
    #endif
    disposeSharedState(destroySynchronously: false)

    videoLayer?.removeFromSuperlayer()
    videoLayer = nil
    containerView?.removeFromSuperview()
    containerView = nil
    mainBlankView?.removeFromSuperview()
    mainBlankView = nil
    isInitialized = false
    print("[MpvPlayerCore] Disposed")
  }

  deinit {
    dispose()
  }

  private func setupNotifications() {
    #if os(iOS)
      let scene = window?.windowScene
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(enterBackground),
        name: UIScene.didEnterBackgroundNotification,
        object: scene
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(enterForeground),
        name: UIScene.willEnterForegroundNotification,
        object: scene
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(sceneDidActivate),
        name: UIScene.didActivateNotification,
        object: scene
      )
    #else
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(enterBackground),
        name: UIApplication.didEnterBackgroundNotification,
        object: nil
      )
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(enterForeground),
        name: UIApplication.willEnterForegroundNotification,
        object: nil
      )
    #endif
  }

  @objc private func enterBackground() {
    isBackgrounded = true
    if isPipActive || isPipStarting {
      print("[MpvPlayerCore] Entering background - PiP active/starting, keeping video")
      return
    }

    print("[MpvPlayerCore] Entering background - disabling video")
    setProperty("vid", value: "no")
  }

  @objc private func enterForeground() {
    isBackgrounded = false
    if isPipActive {
      print("[MpvPlayerCore] Entering foreground - PiP active, skipping vid restore")
      return
    }

    print("[MpvPlayerCore] Entering foreground - enabling video")
    setProperty("vid", value: "auto")
  }

  #if os(iOS)
    @objc private func sceneDidActivate() {
      isBackgrounded = false
      if isPipActive {
        return
      }

      // Restore after the async vid=auto command is acknowledged by MPV so that
      // recoverDisplayLayerIfNeeded and forceDraw run with video actually enabled.
      setPropertyAsync("vid", value: "auto") { [weak self] _ in
        self?.restoreVideoPresentation()
      }
    }
  #endif
}
