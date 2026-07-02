import Cocoa
import Libmpv
import Metal
import QuartzCore

/// Core MPV player using Metal rendering on macOS.
class MpvPlayerCore: MpvPlayerCoreBase {

  private weak var window: NSWindow?
  private var playbackActivity: NSObjectProtocol?
  private var isDisposed = false

  func initialize(in window: NSWindow) -> Bool {
    guard !isInitialized else {
      print("[MpvPlayerCore] Already initialized")
      return true
    }

    guard let contentView = window.contentView else {
      print("[MpvPlayerCore] No content view")
      return false
    }

    self.window = window

    // Create and configure Metal layer for mpv rendering
    let layer = MpvMetalLayer()
    layer.device = MTLCreateSystemDefaultDevice()
    layer.frame = contentView.bounds
    if let screen = window.screen ?? NSScreen.main {
      layer.contentsScale = screen.backingScaleFactor
    }
    layer.framebufferOnly = true
    layer.isOpaque = true
    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

    metalLayer = layer

    contentView.wantsLayer = true
    guard let contentLayer = contentView.layer else {
      print("[MpvPlayerCore] No content layer")
      metalLayer = nil
      return false
    }
    withoutLayerAnimations {
      contentLayer.insertSublayer(layer, at: 0)
      layer.frame = contentView.bounds
    }

    guard setupMpv() else {
      print("[MpvPlayerCore] Failed to setup MPV")
      layer.removeFromSuperlayer()
      metalLayer = nil
      return false
    }

    let center = NotificationCenter.default
    center.addObserver(
      self,
      selector: #selector(windowDidEnterFullScreen),
      name: NSWindow.didEnterFullScreenNotification,
      object: window
    )
    center.addObserver(
      self,
      selector: #selector(windowDidExitFullScreen),
      name: NSWindow.didExitFullScreenNotification,
      object: window
    )
    center.addObserver(
      self,
      selector: #selector(windowOcclusionDidChange),
      name: NSWindow.didChangeOcclusionStateNotification,
      object: window
    )

    isInitialized = true
    print("[MpvPlayerCore] Initialized successfully with MPV")
    return true
  }

  override func configurePlatformMpvOptions() {
    guard let mpv else { return }
    checkError(mpv_set_option_string(mpv, "ao", "avfoundation,coreaudio"))
  }

  func reattachMetalLayer() {
    guard let metalLayer, let contentView = window?.contentView else { return }

    contentView.wantsLayer = true
    if let superlayer = contentView.layer, metalLayer.superlayer !== superlayer {
      withoutLayerAnimations {
        superlayer.backgroundColor = NSColor.black.cgColor
        superlayer.isOpaque = true
        superlayer.insertSublayer(metalLayer, at: 0)
        metalLayer.frame = contentView.bounds
        if let screen = window?.screen ?? NSScreen.main {
          let scale = screen.backingScaleFactor
          metalLayer.contentsScale = scale
          metalLayer.drawableSize = CGSize(
            width: contentView.bounds.width * scale,
            height: contentView.bounds.height * scale
          )
        }
      }
    }

    print("[MpvPlayerCore] Metal layer reattached to window")
  }

  func forceDraw() {
    command(["seek", "0", "relative+exact"])
  }

  private var isVisible = false
  private var pausedState = true
  private var shouldRestoreOnWindowVisible = false

  func setVisible(_ visible: Bool, restoreOnWindowVisible: Bool = false) {
    guard metalLayer != nil, !isPipActive else { return }

    if visible && isVisible && !shouldRestoreOnWindowVisible {
      isBackgrounded = false
      metalLayer?.isHidden = false
      beginPlaybackActivity()
      print("[MpvPlayerCore] setVisible(true) skipped - already visible")
      return
    }

    isVisible = visible
    shouldRestoreOnWindowVisible = !visible && restoreOnWindowVisible
    isBackgrounded = !visible

    if visible {
      shouldRestoreOnWindowVisible = false
      reattachMetalLayer()
      beginPlaybackActivity()
    } else {
      endPlaybackActivity()
    }

    metalLayer?.isHidden = !visible
    print("[MpvPlayerCore] setVisible(\(visible), restoreOnWindowVisible: \(restoreOnWindowVisible))")
  }

  func setPaused(_ paused: Bool) {
    pausedState = paused
    if paused {
      endPlaybackActivity()
    } else if isVisible {
      beginPlaybackActivity()
    }
  }

  func updateFrame(_ frame: CGRect? = nil) {
    guard let metalLayer, !isPipActive else { return }

    let targetFrame: CGRect
    if let frame {
      targetFrame = frame
    } else if let contentView = window?.contentView {
      targetFrame = contentView.bounds
    } else {
      return
    }

    withoutLayerAnimations {
      metalLayer.frame = targetFrame
      if let screen = window?.screen ?? NSScreen.main {
        let scale = screen.backingScaleFactor
        metalLayer.contentsScale = scale
        metalLayer.drawableSize = CGSize(
          width: targetFrame.width * scale,
          height: targetFrame.height * scale
        )
      }
    }
  }

  override func updateEDRMode(sigPeak: Double) {
    guard let metalLayer else { return }

    let hdrEnabled = self.hdrEnabled
    var potentialHeadroom: CGFloat = 1.0
    if let screen = window?.screen ?? NSScreen.main {
      potentialHeadroom = screen.maximumPotentialExtendedDynamicRangeColorComponentValue
    }

    let shouldEnableEDR = hdrEnabled && sigPeak > 1.0 && potentialHeadroom > 1.0
    withoutLayerAnimations {
      metalLayer.wantsExtendedDynamicRangeContent = shouldEnableEDR
    }

    if shouldEnableEDR {
      let peakNits = Int(potentialHeadroom * 80)
      setPropertyAsync("target-peak", value: "\(peakNits)") { _ in }
    } else {
      setPropertyAsync("target-peak", value: "auto") { _ in }
    }

    print(
      "[MpvPlayerCore] EDR mode: \(shouldEnableEDR) (hdrEnabled: \(hdrEnabled), sigPeak: \(sigPeak), potentialHeadroom: \(potentialHeadroom))"
    )
  }

  func dispose() {
    if isDisposed { return }
    isDisposed = true

    endPlaybackActivity()
    NotificationCenter.default.removeObserver(self)
    disposeSharedState(destroySynchronously: false)

    metalLayer?.removeFromSuperlayer()
    metalLayer = nil
    isInitialized = false
    print("[MpvPlayerCore] Disposed")
  }

  deinit {
    dispose()
  }

  @objc private func windowDidEnterFullScreen(_ notification: Notification) {
    guard !isPipActive else { return }
    updateFrame()
  }

  @objc private func windowDidExitFullScreen(_ notification: Notification) {
    guard !isPipActive else { return }
    updateFrame()
  }

  @objc private func windowOcclusionDidChange(_ notification: Notification) {
    guard mpv != nil, !isPipActive else { return }

    let windowVisible = window?.occlusionState.contains(.visible) ?? true
    if !windowVisible {
      print("[MpvPlayerCore] Window occluded")
      isBackgrounded = true
      endPlaybackActivity()
    } else {
      print("[MpvPlayerCore] Window visible")
      isBackgrounded = false
      if !pausedState {
        beginPlaybackActivity()
      }
    }
  }

  private func beginPlaybackActivity() {
    guard playbackActivity == nil else { return }
    playbackActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .latencyCritical],
      reason: "Video playback"
    )
    print("[MpvPlayerCore] Began playback activity assertion")
  }

  private func endPlaybackActivity() {
    guard let playbackActivity else { return }
    ProcessInfo.processInfo.endActivity(playbackActivity)
    self.playbackActivity = nil
    print("[MpvPlayerCore] Ended playback activity assertion")
  }

  private func withoutLayerAnimations(_ updates: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    updates()
    CATransaction.commit()
  }
}
