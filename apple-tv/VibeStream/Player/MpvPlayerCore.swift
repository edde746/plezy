import AVFoundation
import AVKit
import CoreMedia
import Libmpv
import UIKit

/// tvOS MPV player that extends the shared iOS/macOS base.
/// Inherits all MPV setup, event handling, and rendering from MpvPlayerCoreBase.
/// Only adds tvOS-specific lifecycle handling and the shutdown method.
class MpvPlayerCore: MpvPlayerCoreBase {

    private var lifecycleObservers: [NSObjectProtocol] = []

    // MARK: - Initialization

    func initialize(in view: UIView) -> Bool {
        guard !isInitialized else {
            #if DEBUG
            print("[MpvPlayerCore] Already initialized")
            #endif
            return true
        }

        let layer = MpvMetalLayer()
        layer.frame = view.bounds
        layer.contentsScale = UIScreen.main.nativeScale
        layer.framebufferOnly = true
        layer.backgroundColor = UIColor.black.cgColor

        view.layer.addSublayer(layer)
        metalLayer = layer

        #if DEBUG
        print("[MpvPlayerCore] Metal layer added to view, frame: \(layer.frame)")
        #endif

        // Initialize MPV using shared base setup
        guard setupMpv() else {
            #if DEBUG
            print("[MpvPlayerCore] Failed to setup MPV")
            #endif
            layer.removeFromSuperlayer()
            metalLayer = nil
            return false
        }

        isInitialized = true

        // Background lifecycle: pause immediately when resigning active,
        // then disable video output on background to stop the Vulkan/Metal pipeline.
        // Re-enable video output on foreground return.
        lifecycleObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setProperty("pause", value: "yes")
        })
        lifecycleObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setProperty("vid", value: "no")
        })
        lifecycleObservers.append(NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setProperty("vid", value: "auto")
        })

        #if DEBUG
        print("[MpvPlayerCore] Initialized successfully with MPV")
        #endif
        return true
    }

    // MARK: - tvOS EDR & Display Mode Matching

    /// tvOS handles HDR/EDR at the system level — no per-layer EDR control needed.
    override func updateEDRMode(sigPeak: Double) {
        #if DEBUG
        print("[MpvPlayerCore] HDR sig-peak: \(sigPeak) (tvOS handles EDR at system level)")
        #endif
    }

    /// Sets the preferred display criteria to match the video content.
    /// This tells tvOS to switch the HDMI output to the correct mode
    /// (Dolby Vision, HDR10, etc.) matching the content being played.
    func setDisplayCriteria(fps: Float, isDolbyVision: Bool, isHDR10: Bool, bitDepth: Int = 10) {
        guard let window = metalLayer?.superlayer?.delegate as? UIView,
              let uiWindow = window.window else {
            // Try finding the key window
            guard let keyWindow = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene }).first?.windows.first else {
                print("[MpvPlayerCore] No window for display criteria")
                return
            }
            setDisplayCriteriaOnWindow(keyWindow, fps: fps, isDolbyVision: isDolbyVision, isHDR10: isHDR10, bitDepth: bitDepth)
            return
        }
        setDisplayCriteriaOnWindow(uiWindow, fps: fps, isDolbyVision: isDolbyVision, isHDR10: isHDR10, bitDepth: bitDepth)
    }

    private func setDisplayCriteriaOnWindow(_ window: UIWindow, fps: Float, isDolbyVision: Bool, isHDR10: Bool, bitDepth: Int) {
        guard window.responds(to: Selector(("avDisplayManager"))) else {
            print("[MpvPlayerCore] avDisplayManager not available")
            return
        }
        let displayManager = window.avDisplayManager

        guard displayManager.isDisplayCriteriaMatchingEnabled else {
            print("[MpvPlayerCore] Display criteria matching not enabled by user")
            return
        }

        // Create a CMFormatDescription that describes the video's dynamic range
        var formatDescription: CMFormatDescription?
        // Use Dolby Vision HEVC codec type for DV content.
        // 'dvh1' = 0x64766831 — tvOS uses this to distinguish DV from HDR10.
        let dvh1CodecType: CMVideoCodecType = 0x64766831
        let codecType: CMVideoCodecType = isDolbyVision ? dvh1CodecType : kCMVideoCodecType_HEVC

        let extensions: [String: Any]
        if isDolbyVision {
            extensions = [
                kCMFormatDescriptionExtension_TransferFunction as String: kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
                kCMFormatDescriptionExtension_ColorPrimaries as String: kCMFormatDescriptionColorPrimaries_ITU_R_2020,
                kCMFormatDescriptionExtension_YCbCrMatrix as String: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
                kCMFormatDescriptionExtension_BitsPerComponent as String: bitDepth
            ]
        } else if isHDR10 {
            // HDR10: PQ transfer + BT.2020
            extensions = [
                kCMFormatDescriptionExtension_TransferFunction as String: kCMFormatDescriptionTransferFunction_SMPTE_ST_2084_PQ,
                kCMFormatDescriptionExtension_ColorPrimaries as String: kCMFormatDescriptionColorPrimaries_ITU_R_2020,
                kCMFormatDescriptionExtension_YCbCrMatrix as String: kCMFormatDescriptionYCbCrMatrix_ITU_R_2020,
                kCMFormatDescriptionExtension_BitsPerComponent as String: bitDepth
            ]
        } else {
            // SDR
            extensions = [
                kCMFormatDescriptionExtension_TransferFunction as String: kCMFormatDescriptionTransferFunction_ITU_R_709_2,
                kCMFormatDescriptionExtension_ColorPrimaries as String: kCMFormatDescriptionColorPrimaries_ITU_R_709_2,
                kCMFormatDescriptionExtension_YCbCrMatrix as String: kCMFormatDescriptionYCbCrMatrix_ITU_R_709_2
            ]
        }

        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: codecType,
            width: 3840, height: 2160,
            extensions: extensions as CFDictionary,
            formatDescriptionOut: &formatDescription
        )

        guard status == noErr, let desc = formatDescription else {
            print("[MpvPlayerCore] Failed to create format description: \(status)")
            return
        }

        let criteria = AVDisplayCriteria(refreshRate: fps, formatDescription: desc)
        displayManager.preferredDisplayCriteria = criteria

        let rangeStr = isDolbyVision ? "Dolby Vision" : isHDR10 ? "HDR10" : "SDR"
        print("[MpvPlayerCore] Set display criteria: \(fps)fps \(rangeStr)")
    }

    /// Resets display criteria when playback ends.
    /// Note: We intentionally do NOT set preferredDisplayCriteria = nil.
    /// Setting nil causes tvOS to switch away from the user's preferred display mode
    /// (e.g., switching from DV to HDR on app re-open). Let tvOS manage it naturally.
    func resetDisplayCriteria() {
        print("[MpvPlayerCore] Playback ended, letting tvOS manage display criteria")
    }

    // MARK: - Frame Management

    func updateFrame(_ frame: CGRect? = nil) {
        guard let metalLayer, let layer = metalLayer.superlayer else { return }

        let newFrame = frame ?? layer.bounds
        metalLayer.frame = newFrame

        let scale = UIScreen.main.nativeScale
        let newSize = CGSize(
            width: newFrame.width * scale,
            height: newFrame.height * scale
        )
        if abs(metalLayer.drawableSize.width - newSize.width) > 1 ||
           abs(metalLayer.drawableSize.height - newSize.height) > 1 {
            metalLayer.drawableSize = newSize
        }
    }

    // MARK: - Cleanup

    /// Shuts down rendering in preparation for view controller dismiss.
    /// Call this BEFORE triggering the dismiss. dispose() handles the
    /// final mpv_terminate_destroy later.
    func shutdown() {
        guard mpv != nil, !isDisposing else { return }
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers.removeAll()
        command(["stop"])
        if let mpv {
            mpv_set_wakeup_callback(mpv, nil, nil)
        }
        delegate = nil
        metalLayer?.removeFromSuperlayer()
    }

    func dispose() {
        guard !isDisposing else { return }
        lifecycleObservers.forEach { NotificationCenter.default.removeObserver($0) }
        lifecycleObservers.removeAll()
        // Stop rendering before tearing down Metal resources.
        // This gives the GPU time to finish in-flight command buffers
        // that reference the Metal layer's textures.
        command(["stop"])
        if let mpv {
            mpv_set_wakeup_callback(mpv, nil, nil)
        }
        // Delay Metal layer removal to let the GPU drain its queue.
        let layer = metalLayer
        metalLayer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            layer?.removeFromSuperlayer()
        }
        disposeSharedState(destroySynchronously: false)
        isInitialized = false
        #if DEBUG
        print("[MpvPlayerCore] Disposed")
        #endif
    }

    deinit {
        dispose()
    }
}
