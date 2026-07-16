import Cocoa
import Libmpv
import QuartzCore

/// Core MPV player using Metal rendering on macOS.
class MpvPlayerCore: MpvPlayerCoreBase {

  private weak var window: NSWindow?
  private var playbackActivity: NSObjectProtocol?
  private var layerHiddenForOcclusion = false
  private var layerHiddenForScreenSleep = false
  private var isDisposed = false

  /// True while any reason (occlusion, screen sleep) requires the layer hidden.
  private var hasLayerHideReason: Bool {
    layerHiddenForOcclusion || layerHiddenForScreenSleep
  }

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

    let layer = MpvMetalLayer()
    layer.frame = contentView.bounds
    if let screen = window.screen ?? NSScreen.main {
      layer.contentsScale = screen.backingScaleFactor
    }
    layer.framebufferOnly = true
    layer.isOpaque = true
    layer.backgroundColor = NSColor.black.cgColor
    layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

    metalLayer = layer

    contentView.wantsLayer = true
    guard let contentLayer = contentView.layer else {
      print("[MpvPlayerCore] No content layer")
      metalLayer = nil
      return false
    }
    attachMetalLayer(to: contentLayer, frame: contentView.bounds)
    updateEDRMode(sigPeak: lastSigPeak)

    print("[MpvPlayerCore] Metal layer added, frame: \(layer.frame)")

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

    // Display/system sleep does not reliably change occlusionState, so observe
    // NSWorkspace screen sleep/wake directly to gate presentation (prevents a
    // pinned CPU core after long display sleep). This is a DIFFERENT
    // notification center than NotificationCenter.default used above.
    let workspaceCenter = NSWorkspace.shared.notificationCenter
    workspaceCenter.addObserver(
      self,
      selector: #selector(screensDidSleep),
      name: NSWorkspace.screensDidSleepNotification,
      object: nil
    )
    workspaceCenter.addObserver(
      self,
      selector: #selector(screensDidWake),
      name: NSWorkspace.screensDidWakeNotification,
      object: nil
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
    guard let contentView = window?.contentView else { return }

    contentView.wantsLayer = true
    if let contentLayer = contentView.layer {
      attachMetalLayer(to: contentLayer, frame: contentView.bounds)
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
      if metalLayer?.isHidden == true && !hasLayerHideReason {
        setMetalLayerHidden(false)
        redrawIfPausedAndVisible()
      }
      beginPlaybackActivity()
      print("[MpvPlayerCore] setVisible(true) skipped - already visible")
      return
    }

    isVisible = visible
    shouldRestoreOnWindowVisible = !visible && restoreOnWindowVisible
    isBackgrounded = !visible

    if visible {
      shouldRestoreOnWindowVisible = false
      if let contentView = window?.contentView {
        contentView.wantsLayer = true
        if let superlayer = contentView.layer {
          attachMetalLayer(to: superlayer, frame: contentView.bounds)
        }
      }
      beginPlaybackActivity()
    } else {
      endPlaybackActivity()
    }

    setMetalLayerHidden(!visible || hasLayerHideReason)
    if visible {
      redrawIfPausedAndVisible()
    }
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
      updateDrawableSize(for: metalLayer)
    }
    updateEDRMode(sigPeak: lastSigPeak)
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

    print(
      "[MpvPlayerCore] EDR mode: \(shouldEnableEDR) (hdrEnabled: \(hdrEnabled), sigPeak: \(sigPeak), potentialHeadroom: \(potentialHeadroom))"
    )
  }

  func dispose() {
    if isDisposed { return }
    isDisposed = true

    endPlaybackActivity()
    NotificationCenter.default.removeObserver(self)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
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
    guard metalLayer != nil, mpv != nil, !isPipActive else { return }

    let windowVisible = window?.occlusionState.contains(.visible) ?? true
    if !windowVisible && !layerHiddenForOcclusion {
      print("[MpvPlayerCore] Window occluded - hiding Metal layer")
      setMetalLayerHidden(true)
      layerHiddenForOcclusion = true
      isBackgrounded = true
      endPlaybackActivity()
    } else if windowVisible && layerHiddenForOcclusion {
      print("[MpvPlayerCore] Window visible - showing Metal layer")
      layerHiddenForOcclusion = false
      if !layerHiddenForScreenSleep {
        if shouldRestoreOnWindowVisible {
          restoreMetalLayerAfterOcclusion()
        } else {
          setMetalLayerHidden(!isVisible)
        }
        redrawIfPausedAndVisible()
      }
      isBackgrounded = false
      if !pausedState {
        beginPlaybackActivity()
      }
    }
  }

  @objc private func screensDidSleep(_ notification: Notification) {
    guard metalLayer != nil, mpv != nil, !layerHiddenForScreenSleep else { return }
    print("[MpvPlayerCore] Screens did sleep - hiding Metal layer")
    layerHiddenForScreenSleep = true
    // Hide even during PiP: nothing is visible while the displays are dark, and
    // the hidden layer is what gates libmpv presentation (MPVKit >= 1.0.10).
    setMetalLayerHidden(true)
    isBackgrounded = true
    endPlaybackActivity()
  }

  @objc private func screensDidWake(_ notification: Notification) {
    guard metalLayer != nil, mpv != nil, layerHiddenForScreenSleep else { return }
    print("[MpvPlayerCore] Screens did wake - restoring Metal layer")
    layerHiddenForScreenSleep = false

    if isPipActive {
      // Layer is hosted by the PiP window; just unhide it there. Attach/frame
      // logic is owned by the PiP controller.
      setMetalLayerHidden(false)
      isBackgrounded = false
    } else if !layerHiddenForOcclusion {
      if shouldRestoreOnWindowVisible {
        restoreMetalLayerAfterOcclusion()
      } else {
        setMetalLayerHidden(!isVisible)
      }
      isBackgrounded = !isVisible
    }
    // else: window still occluded; windowOcclusionDidChange owns the restore.

    if !layerHiddenForOcclusion && !pausedState {
      beginPlaybackActivity()
    }
    redrawIfPausedAndVisible()
  }

  /// With MPVKit >= 1.0.10, frames produced while the layer was hidden are
  /// skipped at the swapchain, so a paused video would otherwise show a stale
  /// frame after unhiding (upstream regression mpv#16693). Playing video
  /// repaints itself on the next frame; only paused needs a forced draw. The
  /// isHidden guard makes multi-path wake ordering safe — only the path that
  /// actually unhides the layer triggers the single redraw.
  private func redrawIfPausedAndVisible() {
    guard pausedState, metalLayer?.isHidden == false else { return }
    forceDraw()
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

  private func restoreMetalLayerAfterOcclusion() {
    if let metalLayer, let contentView = window?.contentView {
      contentView.wantsLayer = true
      if let superlayer = contentView.layer {
        let targetFrame = contentView.bounds
        let needsAttach = metalLayer.superlayer !== superlayer || superlayer.sublayers?.first !== metalLayer
        if needsAttach {
          attachMetalLayer(to: superlayer, frame: targetFrame)
        } else if !metalLayer.frame.equalTo(targetFrame) {
          updateFrame(targetFrame)
        }
      }
    }
    isVisible = true
    shouldRestoreOnWindowVisible = false
    setMetalLayerHidden(hasLayerHideReason)
  }

  private func attachMetalLayer(to superlayer: CALayer, frame: CGRect) {
    guard let metalLayer else { return }

    withoutLayerAnimations {
      superlayer.backgroundColor = NSColor.black.cgColor
      superlayer.isOpaque = true

      let needsReorder = superlayer.sublayers?.first !== metalLayer
      if metalLayer.superlayer !== superlayer || needsReorder {
        metalLayer.removeFromSuperlayer()
        superlayer.insertSublayer(metalLayer, at: 0)
      }

      metalLayer.frame = frame
      updateDrawableSize(for: metalLayer)
    }
  }

  private func updateDrawableSize(for metalLayer: CAMetalLayer) {
    if let screen = window?.screen ?? NSScreen.main {
      let scale = screen.backingScaleFactor
      metalLayer.contentsScale = scale
      metalLayer.drawableSize = CGSize(
        width: metalLayer.frame.width * scale,
        height: metalLayer.frame.height * scale
      )
    }
  }

  private func setMetalLayerHidden(_ hidden: Bool) {
    withoutLayerAnimations {
      metalLayer?.isHidden = hidden
    }
  }

  private func withoutLayerAnimations(_ updates: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    updates()
    CATransaction.commit()
  }
}
