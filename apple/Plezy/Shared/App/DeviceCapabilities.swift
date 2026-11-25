import AVFoundation
import PlezyKit
import VideoToolbox

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// What this device can do with a playback's output, detected here and reported to shared code (capabilities are
/// native, decisions are shared): the device settings Settings offers, and whether the screen can show HDR, which the
/// playback output's `DisplayInfo` carries to the shared `OutputPolicy`.
extension ApplePlatform {
    /// The device settings this device offers: hardware decoding; HDR output where the screen can show HDR; audio
    /// passthrough on every one: the system's own decoder takes Dolby Digital (Plus) whatever the route,
    /// decoding it for a route that doesn't, so nothing is detected (`MpvPlayerEngine.passthroughCodecs`). The
    /// frame-rate switch only on a Mac
    /// with a screen whose current resolution comes with more than one refresh rate (any screen, since the window can
    /// move; `DisplayModeSwitch`): tvOS asks the TV for every video's rate and its own Match Content setting decides, and
    /// iOS can't force a mode. Discord's switch follows `AppleAppPlatform.discordPresence`, which the shared settings
    /// session reads itself.
    static var deviceFeatures: DeviceFeatures {
        #if os(macOS)
        let matchFrameRate = NSScreen.screens.contains { (DisplayModeSwitch.modes(on: $0)?.variants.count ?? 0) > 1 }
        #else
        let matchFrameRate = false
        #endif
        return DeviceFeatures(
            hardwareDecoding: true,
            hdr: hdrOutputSupported,
            matchFrameRate: matchFrameRate,
            audioPassthrough: true,
            discordPresence: false,
            passthroughTarget: passthroughTarget
        )
    }

    /// What passthrough hands the encoded audio to here (`MpvPlayerEngine.audioOutput`): the system's Dolby decoder
    /// everywhere, and from iOS and tvOS 26 TrueHD Atmos and DTS:X as spatial audio.
    private static var passthroughTarget: PassthroughTarget {
        #if !os(macOS)
        if #available(iOS 26, tvOS 26, *) { return .systemSpatial }
        #endif
        return .systemDecoder
    }

    /// The screen can show HDR video: an EDR screen on iOS and macOS (a potential headroom above SDR white; any of the
    /// Mac's screens, since the window can move), and on tvOS an HDR TV on an Apple TV that decodes HDR (in debug
    /// builds also the simulated one, `SimulatedMatchContent`).
    static var hdrOutputSupported: Bool {
        #if os(tvOS)
        #if DEBUG
        if SimulatedMatchContent.shared != nil { return true }
        #endif
        return AVPlayer.eligibleForHDRPlayback
        #elseif os(iOS)
        (windowScreen?.potentialEDRHeadroom ?? 1) > 1
        #else
        NSScreen.screens.contains { $0.maximumPotentialExtendedDynamicRangeColorComponentValue > 1 }
        #endif
    }

    /// What the screen and the decoders take, for stream picks and suggestions: HDR as above; Dolby Vision as below; the
    /// codecs VideoToolbox decodes in hardware.
    static var videoCapabilities: VideoCapabilities {
        let codecs: [(CMVideoCodecType, VideoCodec)] = [
            (kCMVideoCodecType_H264, .avc), (kCMVideoCodecType_HEVC, .hevc), (kCMVideoCodecType_AV1, .av1), (kCMVideoCodecType_VP9, .vp9),
        ]
        return VideoCapabilities(
            hdr: hdrOutputSupported,
            dolbyVision: dolbyVisionOutputSupported,
            hardwareCodecs: Set(codecs.filter { VTIsHardwareDecodeSupported($0.0) }.map(\.1))
        )
    }

    /// The screen shows Dolby Vision: VideoToolbox decodes Dolby Vision HEVC and the display layer shows the decoded
    /// frames as Dolby Vision on a screen that shows HDR (EDR on iOS and the Mac). On tvOS the TV must take Dolby Vision
    /// too, as AVFoundation reports it (`DisplayCriteria` asks it for its Dolby Vision mode; an HDR10 TV gets HDR10).
    static var dolbyVisionOutputSupported: Bool {
        guard hdrOutputSupported, VTIsHardwareDecodeSupported(kCMVideoCodecType_DolbyVisionHEVC) else { return false }
        #if os(tvOS)
        return AVPlayer.availableHDRModes.contains(.dolbyVision)
        #else
        return true
        #endif
    }

    #if os(iOS)
    /// The screen of the app's window (the first of the app's own scenes, not an external screen's).
    static var windowScreen: UIScreen? {
        UIApplication.shared.connectedScenes.lazy.compactMap { $0 as? UIWindowScene }
            .first { !ExternalDisplay.isExternal($0.session.role) }?.screen
    }
    #endif
}
