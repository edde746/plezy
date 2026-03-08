import Libmpv
import UIKit

/// Core MPV player using Metal rendering for iOS.
class MpvPlayerCore: MpvPlayerCoreBase {

    private var containerView: UIView?
    private weak var window: UIWindow?

    var isPipStarting = false

    func initialize(in window: UIWindow) -> Bool {
        guard !isInitialized else {
            print("[MpvPlayerCore] Already initialized")
            return true
        }

        self.window = window

        let container = UIView(frame: window.bounds)
        container.backgroundColor = .clear
        container.isUserInteractionEnabled = false

        let layer = MpvMetalLayer()
        layer.frame = container.bounds
        layer.contentsScale = UIScreen.main.nativeScale
        layer.framebufferOnly = true
        layer.backgroundColor = UIColor.black.cgColor

        container.layer.addSublayer(layer)
        containerView = container
        metalLayer = layer

        window.insertSubview(container, at: 0)

        guard setupMpv() else {
            print("[MpvPlayerCore] Failed to setup MPV")
            layer.removeFromSuperlayer()
            container.removeFromSuperview()
            metalLayer = nil
            containerView = nil
            return false
        }

        setupNotifications()

        isInitialized = true
        print("[MpvPlayerCore] Initialized successfully with MPV")
        return true
    }

    func switchToPipVO(layerPtr: UnsafeMutableRawPointer) -> Bool {
        guard let mpv else { return false }

        print("[MpvPlayerCore] Switching to pip VO for PiP")

        metalLayer?.removeFromSuperlayer()

        mpv_set_property_string(mpv, "vid", "no")

        var pointer = Int64(Int(bitPattern: layerPtr))
        mpv_set_property(mpv, "wid", MPV_FORMAT_INT64, &pointer)

        mpv_set_property_string(mpv, "vo", "pip")
        mpv_set_property_string(mpv, "vid", "auto")

        print("[MpvPlayerCore] Switched to pip VO successfully")
        return true
    }

    func switchToGpuNextVO() -> Bool {
        guard let mpv, let metalLayer else { return false }

        print("[MpvPlayerCore] Switching back to gpu-next VO")

        mpv_set_property_string(mpv, "vid", "no")

        var layer = metalLayer
        mpv_set_property(mpv, "wid", MPV_FORMAT_INT64, &layer)

        applyGpuNextOptions()
        mpv_set_property_string(mpv, "vid", "auto")

        if metalLayer.superlayer == nil, let containerView {
            containerView.layer.addSublayer(metalLayer)
        }

        print("[MpvPlayerCore] Switched back to gpu-next VO successfully")
        return true
    }

    func setVisible(_ visible: Bool) {
        guard let containerView else { return }

        if visible {
            containerView.removeFromSuperview()
            window?.insertSubview(containerView, at: 0)
        }

        containerView.isHidden = !visible
    }

    func updateFrame(_ frame: CGRect? = nil) {
        guard let metalLayer, let containerView else { return }

        if let frame {
            containerView.frame = frame
            metalLayer.frame = containerView.bounds
        } else if let window {
            containerView.frame = window.bounds
            metalLayer.frame = containerView.bounds
        }

        let scale = UIScreen.main.nativeScale
        metalLayer.drawableSize = CGSize(
            width: metalLayer.frame.width * scale,
            height: metalLayer.frame.height * scale
        )
    }

    /// Nudge mpv to present the current paused frame after switching back from PiP.
    func forceDraw() {
        command(["seek", "0", "relative+exact"])
    }

    override func updateEDRMode(sigPeak: Double) {
        guard let metalLayer else { return }

        var edrHeadroom: CGFloat = 1.0
        if #available(iOS 16.0, *) {
            edrHeadroom = containerView?.window?.screen.potentialEDRHeadroom ?? 1.0
            metalLayer.wantsExtendedDynamicRangeContent =
                hdrEnabled && sigPeak > 1.0 && edrHeadroom > 1.0
        }

        let shouldEnableEDR = hdrEnabled && sigPeak > 1.0 && edrHeadroom > 1.0
        print(
            "[MpvPlayerCore] EDR mode: \(shouldEnableEDR) (hdrEnabled: \(hdrEnabled), sigPeak: \(sigPeak), headroom: \(edrHeadroom))"
        )
    }

    func dispose() {
        NotificationCenter.default.removeObserver(self)
        disposeSharedState(destroySynchronously: false)

        metalLayer?.removeFromSuperlayer()
        metalLayer = nil
        containerView?.removeFromSuperview()
        containerView = nil
        isInitialized = false
        print("[MpvPlayerCore] Disposed")
    }

    deinit {
        dispose()
    }

    private func setupNotifications() {
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
    }

    @objc private func enterBackground() {
        if isPipActive || isPipStarting {
            print("[MpvPlayerCore] Entering background - PiP active/starting, keeping video")
            return
        }

        print("[MpvPlayerCore] Entering background - disabling video")
        if mpv != nil {
            mpv_set_option_string(mpv, "vid", "no")
        }
    }

    @objc private func enterForeground() {
        if isPipActive {
            print("[MpvPlayerCore] Entering foreground - PiP active, skipping vid restore")
            return
        }

        print("[MpvPlayerCore] Entering foreground - enabling video")
        if mpv != nil {
            mpv_set_option_string(mpv, "vid", "auto")
        }
    }
}
