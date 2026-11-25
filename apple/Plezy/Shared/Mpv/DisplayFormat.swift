import PlezyKit

/// What the screen should be set up for while a video plays (display-mode and HDR switching are native, not shared).
/// The engine derives it from mpv once a file's first frame is up and hands it to its `VideoSurface`, which shows it as
/// the shared `OutputPolicy`'s plan says: EDR on iOS and the Mac, `AVDisplayManager` criteria (the shared
/// `AppleDisplayCriteria`) on tvOS. The shown video's fields, as the engine's queue hands them to the main thread.
struct DisplayFormat: Equatable, Sendable {
    var dynamicRange: DynamicRange
    var width: Int
    var height: Int
    /// The video's presented frame rate (`VideoInfo.fps`), in Hz; nil when the track declares none.
    var fps: Double?
    /// The Dolby Vision profile and level of the track (profile 7 as the file has it); nil without Dolby Vision.
    var doviProfile: Int?
    var doviLevel: Int?
    /// `video-params`' peak over SDR white and colour tags (`VideoInfo.sigPeak`, `gamma`, `primaries`, `colorMatrix`).
    var sigPeak: Double?
    var gamma: String?
    var primaries: String?
    var colorMatrix: String?

    /// The shown `video` (`MpvState.videoInfo`) and its track's Dolby Vision level (`MpvState.videoTracks`), which counts
    /// only for Dolby Vision.
    init(video: VideoInfo, doviLevel: Int?) {
        dynamicRange = video.dynamicRange
        width = Int(video.width)
        height = Int(video.height)
        fps = video.fps?.doubleValue
        doviProfile = video.doviProfile?.intValue
        self.doviLevel = video.dynamicRange == .dolbyVision ? doviLevel : nil
        sigPeak = video.sigPeak?.doubleValue
        gamma = video.gamma
        primaries = video.primaries
        colorMatrix = video.colorMatrix
    }

    /// The video again, as the shared rules take it.
    var video: VideoInfo {
        VideoInfo(
            width: Int32(clamping: width),
            height: Int32(clamping: height),
            codec: nil,
            fps: fps.map { KotlinDouble(double: $0) },
            dynamicRange: dynamicRange,
            doviProfile: doviProfile.map { KotlinInt(int: Int32(clamping: $0)) },
            rotation: 0,
            sigPeak: sigPeak.map { KotlinDouble(double: $0) },
            gamma: gamma,
            primaries: primaries,
            colorMatrix: colorMatrix
        )
    }

    /// The video shows above SDR white where the display allows it (iOS's and the Mac's EDR): its peak is above SDR's.
    var extendsDynamicRange: Bool { (sigPeak ?? 0) > 1 }
}

/// The screen as the platform reports it: its mode in pixels and its refresh rate (`PlaybackStats`' display fields),
/// and the dynamic range the video goes out in (`EngineState.outputDynamicRange` where mpv doesn't say); nil where
/// nothing reports it. The engine reads it from its surface (`VideoSurface.displayOutput()`) with each stats reading,
/// and on iOS and tvOS whenever the surface's range may have changed (`onOutputRangeChange`): vo_avfoundation doesn't
/// tell mpv the display's mode, so mpv's `display-width`, `display-height` and `display-fps` stay unavailable.
struct DisplayOutput: Equatable, Sendable {
    var width: Int?
    var height: Int?
    var refreshRate: Double?
    var dynamicRange: DynamicRange?
}
