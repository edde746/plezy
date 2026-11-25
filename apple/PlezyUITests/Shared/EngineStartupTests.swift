import XCTest

/// What mpv takes from the device settings as the player starts, read back from mpv through the player's probe
/// `player.engine` (its `<property>=<value>` fields): `msg-level` and `volume-max` from the debug logging and maximum
/// volume settings, `avfoundation-osd-video-res` from the subtitle render resolution, `audio-exclusive` (on iOS and
/// tvOS, never the Mac's hog mode), the bundled subtitle font, styled subtitles on, the subtitle margins and style, the
/// hardware decoding setting, the read-ahead cache, deinterlacing, and the user's mpv.conf after all of them.
/// `PLEZY_MEDIA_URL` (TEST_ENV MEDIA_URL=…) is the video; else Apple's public HLS sample.
final class EngineStartupTests: PlezyUITestCase {
    private var mediaUrl: String {
        ProcessInfo.processInfo.environment["PLEZY_MEDIA_URL"]
            ?? "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
    }

    #if os(macOS)
    private let exclusive = "audio-exclusive=no"
    #else
    private let exclusive = "audio-exclusive=yes"
    #endif

    func testDefaultSettings() {
        let engine = play(settings: [])
        for field in [
            "msg-level=all=error", "volume-max=100.", "avfoundation-osd-video-res=no", exclusive,
            "sub-use-margins=yes", "sub-font=Go Noto Current-Regular", "sub-ass=yes", "deinterlace=no",
            "sub-bold=no", "sub-ass-override=no", "demuxer-max-bytes=157286400",
        ] {
            XCTAssertTrue(engine.contains(field), "\(field) in \(engine)")
        }
    }

    func testChangedSettings() {
        let engine = play(settings: [
            "enable_debug_logging=true", "subtitle_render_resolution=video", "max_volume=150", "subtitle_use_margins=false",
            "enable_hardware_decoding=false", "playback.cacheSizeMegabytes=64", "deinterlace_mode=video",
            "subtitle_font_size=55", "subtitle_text_color=#FFEE00", "subtitle_bold=true", "subtitle_italic=true",
            "sub_ass_override=strip",
        ])
        for field in [
            "msg-level=all=debug,ffmpeg/video=warn", "volume-max=150.", "avfoundation-osd-video-res=yes", exclusive,
            "sub-use-margins=no", "hwdec-option=no ", "deinterlace=auto", "sub-font-size=55", "sub-bold=yes", "sub-italic=yes",
            "sub-ass-override=strip", "sub-color=#FFFFEE00", "demuxer-max-bytes=67108864",
        ] {
            XCTAssertTrue(engine.contains(field), "\(field) in \(engine)")
        }
    }

    /// The platform's output options as mpv took them (the probe's `<name>-option=` fields): the AVFoundation video
    /// output with its own subtitle layer, hardware decoding for every codec with a software fallback, `keep-open`, and
    /// per platform the audio outputs (`ao`), the host clock (Apple TV, Mac), each file's `hwdec` (VideoToolbox, `no` in
    /// a simulator) and on the Mac `ytdl` off.
    func testPlatformOutputOptions() {
        let engine = play(settings: [])
        var fields = [
            "vo-option=avfoundation", "avfoundation-composite-osd-option=no", "hwdec-codecs-option=all",
            "hwdec-software-fallback-option=yes", "keep-open-option=yes",
        ]
        #if targetEnvironment(simulator)
        fields.append("hwdec-option=no ")
        #else
        fields.append("hwdec-option=videotoolbox ")
        #endif
        #if os(macOS)
        fields += ["ao-option=coreaudio,avfoundation ", "avfoundation-presentation-option=host", "ytdl-option=no"]
        #elseif os(tvOS)
        fields.append("avfoundation-presentation-option=host")
        if #available(tvOS 26, *) { fields.append("ao-option=spatial") }
        #else
        if #available(iOS 26, *) {
            fields.append("ao-option=spatial,avfoundation,audiounit ")
        } else {
            fields.append("ao-option=avfoundation,audiounit ")
        }
        #endif
        for field in fields {
            XCTAssertTrue(engine.contains(field), "\(field) in \(engine)")
        }
    }

    /// The user's mpv.conf comes after the app's own values: its line wins over the subtitle size setting the app writes
    /// as each video opens.
    func testTheUsersMpvConfigComesLast() {
        let engine = play(settings: ["subtitle_font_size=55", "mpv_config_text=sub-font-size=70"])
        XCTAssertTrue(engine.contains("sub-font-size=70"), "sub-font-size=70 in \(engine)")
    }

    /// Plays the video with `settings` and returns the engine probe's reading once mpv has opened it and reported the
    /// subtitle margins, the last of the values to arrive (the playback's subtitle style).
    private func play(settings: [String]) -> String {
        launchDev(settings: settings, arguments: ["--url", mediaUrl])
        let probe = require("player.engine", timeout: 60, "the player's engine probe")
        var value = ""
        let started = waitUntil(60) {
            value = Self.reading(probe)
            return value.contains("ao=") && !value.contains("ao=none") && !value.contains("sub-use-margins=none")
        }
        guard started else {
            fail("the video never started: \(value)")
            return ""
        }
        let report = XCTAttachment(string: value)
        report.name = "engine \(settings.joined(separator: " "))"
        report.lifetime = .keepAlways
        add(report)
        return value
    }

    /// The probe's reading: the Mac's accessibility gives its label, the others its value.
    private static func reading(_ probe: XCUIElement) -> String {
        probe.label.isEmpty ? (probe.value as? String ?? "") : probe.label
    }
}
