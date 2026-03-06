import Cocoa
import Libmpv

/// Core MPV player using Metal rendering.
class MpvPlayerCore: MpvPlayerCoreBase {

    private weak var window: NSWindow?
    private var playbackActivity: NSObjectProtocol?
    private var layerHiddenForOcclusion = false

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
        contentView.layer?.addSublayer(layer)

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
            selector: #selector(windowWillEnterFullScreen),
            name: NSWindow.willEnterFullScreenNotification,
            object: window
        )
        center.addObserver(
            self,
            selector: #selector(windowDidEnterFullScreen),
            name: NSWindow.didEnterFullScreenNotification,
            object: window
        )
        center.addObserver(
            self,
            selector: #selector(windowWillExitFullScreen),
            name: NSWindow.willExitFullScreenNotification,
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
        checkError(mpv_set_option_string(mpv, "vulkan-swap-mode", "mailbox"))
    }

    var videoLayer: CAMetalLayer? { metalLayer }

    func reattachMetalLayer() {
        guard let metalLayer, let contentView = window?.contentView else { return }

        if metalLayer.superlayer == nil {
            contentView.wantsLayer = true
            contentView.layer?.insertSublayer(metalLayer, at: 0)
            metalLayer.frame = contentView.bounds
            if let screen = window?.screen ?? NSScreen.main {
                metalLayer.contentsScale = screen.backingScaleFactor
                metalLayer.drawableSize = CGSize(
                    width: contentView.bounds.width * screen.backingScaleFactor,
                    height: contentView.bounds.height * screen.backingScaleFactor
                )
            }
        }

        print("[MpvPlayerCore] Metal layer reattached to window")
    }

    func forceDraw() {
        command(["seek", "0", "relative+exact"])
    }

    func setVisible(_ visible: Bool) {
        guard let metalLayer, !isPipActive else { return }

        if visible {
            metalLayer.removeFromSuperlayer()
            if let superlayer = window?.contentView?.layer {
                superlayer.insertSublayer(metalLayer, at: 0)
            }
            beginPlaybackActivity()
        } else {
            endPlaybackActivity()
        }

        metalLayer.isHidden = !visible
        print("[MpvPlayerCore] setVisible(\(visible))")
    }

    func updateFrame(_ frame: CGRect? = nil) {
        guard let metalLayer, !isPipActive else { return }

        if let frame {
            metalLayer.frame = frame
        } else if let contentView = window?.contentView {
            metalLayer.frame = contentView.bounds
        }

        if let screen = window?.screen ?? NSScreen.main {
            let scale = screen.backingScaleFactor
            metalLayer.drawableSize = CGSize(
                width: metalLayer.frame.width * scale,
                height: metalLayer.frame.height * scale
            )
        }

        print("[MpvPlayerCore] updateFrame: \(metalLayer.frame)")
    }

    override func updateEDRMode(sigPeak: Double) {
        guard let metalLayer else { return }

        var edrHeadroom: CGFloat = 1.0
        if let screen = window?.screen ?? NSScreen.main {
            edrHeadroom = screen.maximumExtendedDynamicRangeColorComponentValue
        }

        let shouldEnableEDR = hdrEnabled && sigPeak > 1.0 && edrHeadroom > 1.0
        metalLayer.wantsExtendedDynamicRangeContent = shouldEnableEDR

        print(
            "[MpvPlayerCore] EDR mode: \(shouldEnableEDR) (hdrEnabled: \(hdrEnabled), sigPeak: \(sigPeak), headroom: \(edrHeadroom))"
        )
    }

    func dispose() {
        endPlaybackActivity()
        NotificationCenter.default.removeObserver(self)
        disposeSharedState(destroySynchronously: true)

        metalLayer?.removeFromSuperlayer()
        metalLayer = nil
        isInitialized = false
        print("[MpvPlayerCore] Disposed")
    }

    deinit {
        dispose()
    }

    @objc private func windowWillEnterFullScreen(_ notification: Notification) {
        guard mpv != nil, !isPipActive else { return }
        print("[MpvPlayerCore] willEnterFullScreen - disabling video output")
        mpv_set_property_string(mpv, "vid", "no")
    }

    @objc private func windowDidEnterFullScreen(_ notification: Notification) {
        guard mpv != nil, !isPipActive else { return }
        print("[MpvPlayerCore] didEnterFullScreen - re-enabling video output")
        mpv_set_property_string(mpv, "vid", "auto")
    }

    @objc private func windowWillExitFullScreen(_ notification: Notification) {
        guard mpv != nil, !isPipActive else { return }
        print("[MpvPlayerCore] willExitFullScreen - disabling video output")
        mpv_set_property_string(mpv, "vid", "no")
    }

    @objc private func windowDidExitFullScreen(_ notification: Notification) {
        guard mpv != nil, !isPipActive else { return }
        print("[MpvPlayerCore] didExitFullScreen - re-enabling video output")
        mpv_set_property_string(mpv, "vid", "auto")
    }

    @objc private func windowOcclusionDidChange(_ notification: Notification) {
        guard let metalLayer, mpv != nil, !isPipActive else { return }

        let isVisible = window?.occlusionState.contains(.visible) ?? true
        if !isVisible && !layerHiddenForOcclusion {
            print("[MpvPlayerCore] Window occluded - hiding Metal layer")
            metalLayer.isHidden = true
            layerHiddenForOcclusion = true
        } else if isVisible && layerHiddenForOcclusion {
            print("[MpvPlayerCore] Window visible - showing Metal layer")
            layerHiddenForOcclusion = false
            metalLayer.isHidden = false
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
}
