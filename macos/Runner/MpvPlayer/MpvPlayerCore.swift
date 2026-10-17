import AVFoundation
import Cocoa
import Libmpv
import QuartzCore

/// The plain layer at the bottom of the window's content layer that holds
/// mpv's display layer. vo_avfoundation adds its OSD layer beside the display
/// layer here, so subtitles and the video both stay below Flutter. It never
/// animates: AppKit resizes it with the window and the core hides it, and an
/// implicit fade or slide would trail both.
private final class MpvVideoContainerLayer: CALayer {
  weak var videoLayer: CALayer?

  override func action(forKey event: String) -> CAAction? { nil }

  /// Sizes the display layer through bounds and position, never `frame`,
  /// which the zoom transform leaves undefined. The OSD sibling follows its
  /// autoresizing mask and the VO's bounds observer.
  override func layoutSublayers() {
    super.layoutSublayers()
    guard let videoLayer, videoLayer.superlayer === self else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    videoLayer.bounds = CGRect(origin: .zero, size: bounds.size)
    videoLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
    CATransaction.commit()
  }
}

/// Core MPV player using AVFoundation sample-buffer rendering on macOS.
class MpvPlayerCore: MpvPlayerCoreBase {

  private weak var window: NSWindow?
  private var containerLayer: MpvVideoContainerLayer?
  private var playbackActivity: NSObjectProtocol?
  private var layerHiddenForOcclusion = false
  private var layerHiddenForScreenSleep = false
  /// The viewer's zoom, kept so the display layer gets it back after PiP,
  /// which shows the whole picture.
  private var videoZoomScale = 1.0

  /// True while any reason (occlusion, screen sleep) requires the layer hidden.
  private var hasLayerHideReason: Bool {
    layerHiddenForOcclusion || layerHiddenForScreenSleep
  }

  func initialize(in window: NSWindow) -> Bool {
    guard !isInitialized else {
      MpvLog.debug("[MpvPlayerCore] Already initialized")
      return true
    }

    guard let contentView = window.contentView else {
      MpvLog.debug("[MpvPlayerCore] No content view")
      return false
    }

    self.window = window

    let container = MpvVideoContainerLayer()
    container.frame = contentView.bounds
    container.backgroundColor = NSColor.black.cgColor
    container.isOpaque = true
    container.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

    let layer = MpvVideoLayer()
    layer.frame = container.bounds
    layer.isOpaque = true
    layer.backgroundColor = NSColor.black.cgColor
    layer.videoGravity = .resizeAspect
    container.addSublayer(layer)
    container.videoLayer = layer

    containerLayer = container
    videoLayer = layer

    contentView.wantsLayer = true
    guard let contentLayer = contentView.layer else {
      MpvLog.debug("[MpvPlayerCore] No content layer")
      containerLayer = nil
      videoLayer = nil
      return false
    }
    attachContainerLayer(to: contentLayer, frame: contentView.bounds)

    MpvLog.debug("[MpvPlayerCore] Video layer added, frame: \(container.frame)")

    guard setupMpv() else {
      MpvLog.debug("[MpvPlayerCore] Failed to setup MPV")
      container.removeFromSuperlayer()
      containerLayer = nil
      videoLayer = nil
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
    center.addObserver(
      self,
      selector: #selector(windowDidChangeBackingProperties),
      name: NSWindow.didChangeBackingPropertiesNotification,
      object: window
    )

    // Display/system sleep does not reliably change occlusionState, so observe
    // NSWorkspace screen sleep/wake directly. This is a DIFFERENT notification
    // center than NotificationCenter.default used above.
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
    MpvLog.debug("[MpvPlayerCore] Initialized successfully with MPV")
    return true
  }

  func forceDraw() {
    command(["seek", "0", "relative+exact"])
  }

  private var isVisible = false
  private var pausedState = true
  private var shouldRestoreOnWindowVisible = false

  func setVisible(_ visible: Bool, restoreOnWindowVisible: Bool = false) {
    guard containerLayer != nil, !isPipActive else { return }

    if visible && isVisible && !shouldRestoreOnWindowVisible {
      setBackgrounded(false)
      if containerLayer?.isHidden == true && !hasLayerHideReason {
        setContainerHidden(false)
        recoverDisplayLayerIfNeeded()
      }
      beginPlaybackActivity()
      MpvLog.debug("[MpvPlayerCore] setVisible(true) skipped - already visible")
      return
    }

    isVisible = visible
    shouldRestoreOnWindowVisible = !visible && restoreOnWindowVisible
    setBackgrounded(!visible)

    if visible {
      shouldRestoreOnWindowVisible = false
      if let contentView = window?.contentView {
        contentView.wantsLayer = true
        if let superlayer = contentView.layer {
          attachContainerLayer(to: superlayer, frame: contentView.bounds)
        }
      }
      beginPlaybackActivity()
    } else {
      endPlaybackActivity()
    }

    setContainerHidden(!visible || hasLayerHideReason)
    if visible {
      recoverDisplayLayerIfNeeded()
    }
    MpvLog.debug("[MpvPlayerCore] setVisible(\(visible), restoreOnWindowVisible: \(restoreOnWindowVisible))")
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
    guard let containerLayer else { return }

    let targetFrame: CGRect
    if let frame {
      targetFrame = frame
    } else if let contentView = window?.contentView {
      targetFrame = contentView.bounds
    } else {
      return
    }

    withoutLayerAnimations {
      containerLayer.frame = targetFrame
      updateContentsScale()
    }
  }

  /// Applies viewer zoom by scaling the display layer about its centre.
  ///
  /// Zoom must never reach mpv's `video-zoom` on this VO: any nonzero zoom
  /// flips vo_avfoundation into a Core Image re-render of every frame, which
  /// destroys HDR/Dolby Vision passthrough. The transform sits on the display
  /// layer itself, as on iOS; its bounds never change, so the VO's bounds
  /// observer stays quiet and the OSD sibling keeps its geometry.
  func setVideoZoom(_ scale: Double) {
    let clamped = min(max(scale, 0.25), 4.0)
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.videoZoomScale = clamped
      self.applyVideoZoom()
    }
  }

  private func applyVideoZoom() {
    guard let containerLayer, let videoLayer, videoLayer.superlayer === containerLayer else { return }
    let zoomed = abs(videoZoomScale - 1.0) >= 0.0005
    withoutLayerAnimations {
      // Clip only while zoomed: at 100% the layer tree stays identical to an
      // unzoomed one, so the plain path cannot regress.
      containerLayer.masksToBounds = zoomed
      videoLayer.transform =
        zoomed
        ? CATransform3DMakeScale(CGFloat(videoZoomScale), CGFloat(videoZoomScale), 1)
        : CATransform3DIdentity
    }
  }

  /// Hands the display layer and vo_avfoundation's OSD layer beside it to the
  /// PiP window, which sizes them from then on. They leave unzoomed: PiP
  /// shows the whole picture.
  func lendVideoLayersForPip() -> [CALayer]? {
    guard let containerLayer, let layers = containerLayer.sublayers, !layers.isEmpty else { return nil }
    withoutLayerAnimations {
      containerLayer.masksToBounds = false
      videoLayer?.transform = CATransform3DIdentity
      layers.forEach { $0.removeFromSuperlayer() }
    }
    return layers
  }

  /// PiP closed: the layers it hosted come back into the container at the
  /// container's size, with the viewer's zoom.
  func takeBackVideoLayers(_ layers: [CALayer]) {
    guard let containerLayer else { return }
    withoutLayerAnimations {
      layers.forEach { containerLayer.addSublayer($0) }
    }
    if let contentView = window?.contentView, let contentLayer = contentView.layer {
      attachContainerLayer(to: contentLayer, frame: contentView.bounds)
    }
    applyVideoZoom()
    recoverDisplayLayerIfNeeded()
  }

  /// EDR lets the display layer show HDR above SDR white; off, the system
  /// tone-maps HDR frames to SDR.
  override func updateEDRMode(sigPeak: Double) {
    guard let videoLayer else { return }
    let shouldEnableEDR = hdrEnabled && sigPeak > 1.0
    withoutLayerAnimations {
      if #available(macOS 26.0, *) {
        videoLayer.preferredDynamicRange = shouldEnableEDR ? .high : .standard
      } else {
        videoLayer.wantsExtendedDynamicRangeContent = shouldEnableEDR
      }
    }
  }

  func dispose() {
    guard beginDisposal() else { return }
    endPlaybackActivity()
    NotificationCenter.default.removeObserver(self)
    NSWorkspace.shared.notificationCenter.removeObserver(self)
    disposeSharedState(destroySynchronously: false)

    videoLayer?.removeFromSuperlayer()
    containerLayer?.removeFromSuperlayer()
    videoLayer = nil
    containerLayer = nil
    isInitialized = false
    MpvLog.debug("[MpvPlayerCore] Disposed")
  }

  deinit {
    dispose()
  }

  @objc private func windowDidEnterFullScreen(_ notification: Notification) {
    updateFrame()
  }

  @objc private func windowDidExitFullScreen(_ notification: Notification) {
    updateFrame()
  }

  @objc private func windowDidChangeBackingProperties(_ notification: Notification) {
    updateFrame()
  }

  @objc private func windowOcclusionDidChange(_ notification: Notification) {
    guard containerLayer != nil, hasActiveMpv, !isPipActive else { return }

    let windowVisible = window?.occlusionState.contains(.visible) ?? true
    if !windowVisible && !layerHiddenForOcclusion {
      MpvLog.debug("[MpvPlayerCore] Window occluded - hiding video layer")
      setContainerHidden(true)
      layerHiddenForOcclusion = true
      setBackgrounded(true)
      endPlaybackActivity()
    } else if windowVisible && layerHiddenForOcclusion {
      MpvLog.debug("[MpvPlayerCore] Window visible - showing video layer")
      layerHiddenForOcclusion = false
      if !layerHiddenForScreenSleep {
        if shouldRestoreOnWindowVisible {
          restoreContainerAfterOcclusion()
        } else {
          setContainerHidden(!isVisible)
        }
        recoverDisplayLayerIfNeeded()
      }
      setBackgrounded(false)
      if !pausedState {
        beginPlaybackActivity()
      }
    }
  }

  @objc private func screensDidSleep(_ notification: Notification) {
    guard containerLayer != nil, hasActiveMpv, !layerHiddenForScreenSleep else { return }
    MpvLog.debug("[MpvPlayerCore] Screens did sleep - hiding video layer")
    layerHiddenForScreenSleep = true
    setContainerHidden(true)
    setBackgrounded(true)
    endPlaybackActivity()
  }

  @objc private func screensDidWake(_ notification: Notification) {
    guard containerLayer != nil, hasActiveMpv, layerHiddenForScreenSleep else { return }
    MpvLog.debug("[MpvPlayerCore] Screens did wake - restoring video layer")
    layerHiddenForScreenSleep = false

    if isPipActive {
      // The PiP window hosts the video layers; the container has nothing to show.
      setBackgrounded(false)
    } else if !layerHiddenForOcclusion {
      if shouldRestoreOnWindowVisible {
        restoreContainerAfterOcclusion()
      } else {
        setContainerHidden(!isVisible)
      }
      setBackgrounded(!isVisible)
    }
    // else: window still occluded; windowOcclusionDidChange owns the restore.

    if !layerHiddenForOcclusion && !pausedState {
      beginPlaybackActivity()
    }
    recoverDisplayLayerIfNeeded()
  }

  /// A display layer that failed while it was out of sight shows nothing
  /// until flushed. Playing video refills it with its next frames; a paused
  /// one needs a redraw.
  private func recoverDisplayLayerIfNeeded() {
    guard let videoLayer, containerLayer?.isHidden == false || isPipActive else { return }
    guard videoLayer.status == .failed || videoLayer.requiresFlushToResumeDecoding else { return }
    MpvLog.debug("[MpvPlayerCore] Flushing failed display layer")
    videoLayer.flush()
    if pausedState { forceDraw() }
  }

  private func beginPlaybackActivity() {
    guard playbackActivity == nil else { return }
    playbackActivity = ProcessInfo.processInfo.beginActivity(
      options: [.userInitiated, .latencyCritical],
      reason: "Video playback"
    )
    MpvLog.debug("[MpvPlayerCore] Began playback activity assertion")
  }

  private func endPlaybackActivity() {
    guard let playbackActivity else { return }
    ProcessInfo.processInfo.endActivity(playbackActivity)
    self.playbackActivity = nil
    MpvLog.debug("[MpvPlayerCore] Ended playback activity assertion")
  }

  private func restoreContainerAfterOcclusion() {
    if let containerLayer, let contentView = window?.contentView {
      contentView.wantsLayer = true
      if let superlayer = contentView.layer {
        let targetFrame = contentView.bounds
        let needsAttach =
          containerLayer.superlayer !== superlayer || superlayer.sublayers?.first !== containerLayer
        if needsAttach {
          attachContainerLayer(to: superlayer, frame: targetFrame)
        } else if !containerLayer.frame.equalTo(targetFrame) {
          updateFrame(targetFrame)
        }
      }
    }
    isVisible = true
    shouldRestoreOnWindowVisible = false
    setContainerHidden(hasLayerHideReason)
  }

  private func attachContainerLayer(to superlayer: CALayer, frame: CGRect) {
    guard let containerLayer else { return }

    withoutLayerAnimations {
      superlayer.backgroundColor = NSColor.black.cgColor
      superlayer.isOpaque = true

      let needsReorder = superlayer.sublayers?.first !== containerLayer
      if containerLayer.superlayer !== superlayer || needsReorder {
        containerLayer.removeFromSuperlayer()
        superlayer.insertSublayer(containerLayer, at: 0)
      }

      containerLayer.frame = frame
      updateContentsScale()
    }
  }

  /// The VO observes the display layer's contentsScale to size its OSD, so
  /// it follows the window's screen. While PiP hosts the display layer, the
  /// PiP window owns its scale.
  private func updateContentsScale() {
    guard let containerLayer else { return }
    let scale = window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 2
    containerLayer.contentsScale = scale
    if let videoLayer, videoLayer.superlayer === containerLayer, videoLayer.contentsScale != scale {
      videoLayer.contentsScale = scale
    }
  }

  private func setContainerHidden(_ hidden: Bool) {
    withoutLayerAnimations {
      containerLayer?.isHidden = hidden
    }
  }

  private func withoutLayerAnimations(_ updates: () -> Void) {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    updates()
    CATransaction.commit()
  }
}
