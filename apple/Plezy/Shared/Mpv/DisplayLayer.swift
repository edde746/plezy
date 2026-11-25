import AVFoundation
import OSLog
import PlezyKit

/// The `AVSampleBufferDisplayLayer` mpv's avfoundation VO presents into, as every surface with one shows it: iOS's and
/// tvOS's `VideoSurface` (UIKit) and the Mac's with the AVFoundation output (AppKit). Each surface keeps what its view
/// decides: the scale it reads, the clipping around the layer, and on tvOS `AVDisplayManager` criteria instead of EDR.
extension AVSampleBufferDisplayLayer {
    /// The layer at the size of `container`, centred in it, at `scale`: bounds and position rather than frame, which the
    /// zoom transform (`show`) changes, and no implicit animation, as the VO tracks the layer's bounds and contentsScale
    /// for the output's size in pixels.
    func place(in container: CGRect, scale: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bounds = CGRect(origin: .zero, size: container.size)
        position = CGPoint(x: container.midX, y: container.midY)
        contentsScale = scale
        CATransaction.commit()
    }

    /// Shows the picture with `fit` and `zoom` (the player's `VideoLayout`, from the engine): the fit as the layer's
    /// gravity (`resizeAspectFill` for `COVER`, else `resizeAspect`), a stretch (`FILL`: `stretchX` and `stretchY` scale
    /// the picture as the layer fits it to the whole surface) and the zoom as a scale of the layer about its centre,
    /// `clip` clipping it to the view around only while zoomed. The layer's bounds stay, so the
    /// VO, which tracks them, sees no change; the transform sits on the display layer itself, as the video plane ignores
    /// a container's sublayer transform. Picture in picture shows the layer's frames, not its transform.
    func show(fit: VideoFit, zoom: Double, stretchX: Double, stretchY: Double, clip: (Bool) -> Void) {
        let gravity: AVLayerVideoGravity = fit == .cover ? .resizeAspectFill : .resizeAspect
        let zoomed = abs(zoom - 1) >= 0.0005
        let scaleX = zoom * stretchX
        let scaleY = zoom * stretchY
        let identity = abs(scaleX - 1) < 0.0005 && abs(scaleY - 1) < 0.0005
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if videoGravity != gravity { videoGravity = gravity }
        clip(zoomed)
        transform = identity ? CATransform3DIdentity : CATransform3DMakeScale(scaleX, scaleY, 1)
        CATransaction.commit()
        Logger(subsystem: "com.edde746.plezy", category: "display")
            .notice("video layer gravity=\(gravity.rawValue, privacy: .public) scale=\(scaleX)x\(scaleY)")
    }

    #if !os(tvOS)
    /// EDR lets the layer show HDR frames above SDR white; off, the system tone-maps them to SDR.
    func showExtendedDynamicRange(_ enabled: Bool) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        if #available(iOS 26.0, macOS 26.0, *) {
            preferredDynamicRange = enabled ? .high : .standard
        } else {
            wantsExtendedDynamicRangeContent = enabled
        }
        CATransaction.commit()
        Logger(subsystem: "com.edde746.plezy", category: "display")
            .notice("display layer EDR \(enabled ? "on" : "off", privacy: .public)")
    }
    #endif
}
