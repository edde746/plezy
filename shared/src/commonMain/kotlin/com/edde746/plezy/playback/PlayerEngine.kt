package com.edde746.plezy.playback

import com.edde746.plezy.data.settings.DolbyVisionConversion

/**
 * The port every platform's mpv glue implements: Kotlin + JNI on Android, JVM FFM on desktop, Swift
 * on Apple. Callback-based and ObjC-friendly so Swift can implement it through the exported framework.
 * Platform options (`vo`, `wid`, `gpu-*`, passthrough, HDR) stay inside each implementation; every engine sets
 * [COMMON_MPV_OPTIONS] before them, and `hwdec` and the demuxer cache come with each file ([LoadRequest.options]),
 * decided by the shared [PlaybackOptions]. What a load sets in mpv ([com.edde746.plezy.playback.mpv.MpvLoad]), each
 * file's lifecycle and how mpv's properties become [EngineState] ([com.edde746.plezy.playback.mpv.MpvLifecycle], on
 * [com.edde746.plezy.playback.mpv.MpvState]'s rules) are shared; each engine keeps the transport. [EngineState.loadId],
 * [EngineState.loaded] and [EngineState.buffering] are the contract every engine meets.
 *
 * Threading: calls may come from any thread; implementations serialize them. [PlayerEngineListener.onState] may be
 * invoked from any thread.
 */
interface PlayerEngine {
    /**
     * Opens [request]'s file in place of the one open; returns the load's id, which every [EngineState] from then on
     * carries ([EngineState.loadId]) until the next load.
     */
    fun load(request: LoadRequest): Long

    /**
     * Unloads the open file: its decoders and audio output go back to the system (a TV in the background), the engine
     * stays for the next [load]. Its reports after this aren't the file's.
     */
    fun stop()
    fun setPaused(paused: Boolean)
    fun seek(seconds: Double, exact: Boolean)

    /** Playback speed factor; 1.0 is normal speed (mpv `speed`). */
    fun setSpeed(speed: Double)

    /** Positive values show subtitles later, the second subtitle too (mpv `sub-delay`, `secondary-sub-delay`). */
    fun setSubtitleDelay(seconds: Double)

    /** Positive values play audio later (mpv `audio-delay`). */
    fun setAudioDelay(seconds: Double)

    /**
     * Keeps bottom subtitles clear of the player's controls while they cover [fraction] (0–1) of the video surface's
     * height from its bottom edge; 0 puts them back in the place the subtitle style gives them. mpv: `sub-pos` =
     * [SubtitleStyle.position] of the latest style ([setSubtitleStyle]; [SubtitleStyle.DEFAULT] before one) in the
     * frame the engine has mpv place text subtitles in ([SubtitleFrame]): the whole surface, where they move up by
     * [fraction] of it, or the picture (`sub-use-margins=no`), where they move up by the part of the controls over the
     * picture, from mpv's `osd-dimensions` (nothing while the controls stay in the band below it), again whenever those
     * change (a rotation, a resize, another file). The style may lift them further. `sub-pos` moves text and image
     * subtitles (the latter, and ASS files, by a share of the picture's height; lines an ASS file positions itself
     * stay). The player store calls it as its controls come and go (`PlayerStore.onControlsHeightChanged`).
     */
    fun setSubtitleLift(fraction: Double)

    /**
     * Draws subtitles in [style] from now on, on the file playing too (a paused picture redraws): every mpv property
     * of [SubtitleStyle.properties], and `sub-pos` again ([setSubtitleLift]). The style outlives files; the playback
     * session sends it as it starts and whenever this device's subtitle settings change.
     */
    fun setSubtitleStyle(style: SubtitleStyle)

    /** 0–100 is the normal range; up to [VOLUME_MAX] amplifies (mpv `volume`, `volume-max`). */
    fun setVolume(volume: Double)
    fun setMuted(muted: Boolean)

    /**
     * Shows the picture as [layout] says, from now on and for the files after this one ([VideoLayout]; the player store
     * sends it as the playback starts and whenever the viewer changes it). Where mpv scales the picture (the GL and
     * Vulkan outputs) these are [VideoLayout.properties]. Where the platform scales it itself (Android's video plane,
     * the iOS and tvOS display layer) the view's geometry follows [layout] the same way, and mpv keeps the properties
     * that place its subtitles and OSD to match; a display layer zooms by its own transform and leaves `video-zoom` at
     * 0 (vo_avfoundation would re-render every frame through Core Image, losing HDR). Subtitles stay on the surface:
     * an engine that places plain-text subtitles by the picture (`sub-use-margins=no`) places them by the surface while
     * the picture [VideoLayout.overflows] it, and lifts them for the controls in that frame ([setSubtitleLift]).
     */
    fun setVideoLayout(layout: VideoLayout)

    /**
     * Runs the user shaders at [paths] over the picture, in order, from now on and for the files after this one; empty
     * for none (mpv `glsl-shaders`, set as a whole list). The player store sends what the shader preset needs
     * ([ShaderPreset.files]). An output that renders no user shaders moves to one that does while the list isn't
     * empty: Android leaves its video plane (`vo=mediacodec`) for the GPU output.
     */
    fun setShaders(paths: List<String>)

    /**
     * Ambient lighting ([AmbientLightingController]) with the shader at [shaderPath], or off for null; kept for the
     * files after this one. On, mpv hands its subtitles the picture's aspect (`sub-video-rect-aspect`, kept to each
     * file's), runs the shader after the user shaders (kept last when they change) and scales the picture to the whole
     * output (`keepaspect=no`) for the shader to place it back; off undoes them in reverse. An output that runs no
     * user shaders ignores it; Android leaves its video plane for the GPU output.
     */
    fun setAmbientLighting(shaderPath: String?)

    /**
     * Evens out the loudness, or plays the audio as it is: [LOUDNESS_NORMALIZATION_FILTER] in mpv's `af` (empty for
     * off), [ANDROID_LOUDNESS_NORMALIZATION_FILTER] on Android. A filter can't process a bitstream: while it is on,
     * the audio is decoded, never passed through.
     */
    fun setAudioNormalization(enabled: Boolean)

    /**
     * The most channels the audio plays with, folded down as [downmix] says (mpv: [channelLimitWrites]). The stereo
     * limit decodes the audio, never passing it through; the 5.1 limit only shapes decoded audio.
     */
    fun setAudioChannels(channels: AudioChannels, downmix: Downmix = Downmix())

    /**
     * Plays to [name], an entry of [EngineState.audioDevices] (mpv `audio-device`); "auto" is the system's choice. An
     * engine whose platform routes audio itself (Android, iOS, tvOS) reports no devices and ignores this.
     */
    fun setAudioDevice(name: String)

    /**
     * Whether the playback info or the performance overlay shows, which read [EngineState.stats]: while [wanted], the
     * engine reads them at once and then every [STATS_INTERVAL_MS] ([PlaybackStats] names mpv's properties), and
     * publishes each reading; it reads nothing for them otherwise, and [EngineState.stats] is null. Off until called;
     * it outlives files (a load drops the last file's reading, the next reading is the new file's). The player store
     * calls it as the info or the overlay opens and closes.
     */
    fun setStatsWanted(wanted: Boolean)

    /** `id == null` turns the track kind off (e.g. no subtitles). */
    fun selectTrack(kind: TrackKind, id: Long?)

    /**
     * Shows subtitle track [id] as the second subtitle, at the top of the picture (mpv `secondary-sid`, drawn in the
     * subtitle style); null turns it off. mpv refuses a track that is the first subtitle here, and the second subtitle's
     * track as the first ([selectTrack]): the caller turns one off before it moves a track to the other.
     */
    fun selectSecondSubtitle(id: Long?)

    /**
     * Adds the subtitle file at [url] to the current file as a track, without selecting it ([selectTrack] does). The
     * playback session hands it a file on this device only ([com.edde746.plezy.playback.session.SidecarFetcher]), so
     * adding one never waits on a network.
     */
    fun addSubtitle(url: String, title: String?, lang: String?)

    /**
     * Saves a screenshot of the video with its subtitles where the engine keeps them (mpv's `screenshot subtitles`, to
     * its screenshot directory); [onResult] hears, on any thread, whether it was saved. An engine without screenshots
     * answers false.
     */
    fun screenshot(onResult: (saved: Boolean) -> Unit)

    /** Seeks to the next ([forward]) or previous subtitle line's start (mpv's `sub-seek`); nothing where the engine can't. */
    fun subtitleSeek(forward: Boolean)

    /** What this engine offers beyond the common contract, as it starts ([EngineFeatures]). */
    val features: EngineFeatures

    /**
     * Whether the picture may go out as HDR ([com.edde746.plezy.playback.output.OutputPlan.hdrOutput]): the playback's
     * output plan writes it, the player's HDR switch and the Hdr setting being inputs to that plan, and nothing else
     * does. mpv's `target-colorspace-hint` (`auto`, or `no`, which tone-maps HDR video to SDR), the video plane's own
     * decision on Wayland, the video Surface's HDR headroom on Android. [onResult] hears, on any thread, whether the
     * engine took it: false where mpv refused the write, or HDR was asked of an output that can never carry it (a
     * Wayland plane on a compositor without colour management).
     */
    fun setHdrOutput(enabled: Boolean, onResult: (applied: Boolean) -> Unit = {})

    /**
     * What Dolby Vision Profile 7 becomes ([DolbyVisionConversion.wire]: `auto`, `disabled`, `dv81`, `hevc_strip`), as
     * the output plan has it ([com.edde746.plezy.playback.output.OutputPlan.dolbyVisionConversion]: the setting, or a
     * development build's player page in its place), taken at the next Dolby Vision decoder the engine opens. The plan
     * writes it, and nothing else does. Nothing where [EngineFeatures.dolbyVisionConversion] is false.
     */
    fun setDolbyVisionConversion(mode: DolbyVisionConversion)

    fun setListener(listener: PlayerEngineListener?)

    /** Stops playback and frees native resources. The engine is unusable afterwards. */
    fun release()
}

/**
 * What a [PlayerEngine] can't do everywhere. The output plan decides HDR output and Dolby Vision conversion; these say
 * only where an engine can't follow a change of them while it plays.
 *
 * @param hdrControl the engine switches HDR output while it plays ([PlayerEngine.setHdrOutput]), so the player offers
 *   its HDR switch: mpv on iOS, Apple TV (where the TV's criteria follow it), the Mac and Windows, and on Linux where
 *   the compositor describes HDR to the video plane. Not on Android, where the video Surface drops HDR only from API
 *   35 (and Plezy's Android player never had the switch).
 * @param audioDevices the outputs to pick from ([EngineState.audioDevices]) are listed, an empty list meaning none was
 *   found: mpv on the desktop and the Mac. Elsewhere the platform routes the audio and the list stays empty.
 * @param dolbyVisionConversion the engine converts Dolby Vision Profile 7 ([PlayerEngine.setDolbyVisionConversion]):
 *   mpv on Android and Apple's platforms; the desktop's mpv has no conversion.
 */
data class EngineFeatures(
    val hdrControl: Boolean = false,
    val audioDevices: Boolean = false,
    val dolbyVisionConversion: Boolean = false,
)

interface PlayerEngineListener {
    fun onState(state: EngineState)
}

/**
 * Every value of the load reaches mpv as its property, set right before a plain loadfile, never as a per-file option,
 * which mpv drops on the files it opens from the file's playlist (an HLS open that failed falls back to its entries).
 *
 * @param url the final (already resolved) stream URL.
 * @param options the file's decoding and cache options, from this device's settings when it loads: the engine applies
 *   them to this file (a test run's own mpv option of the same name wins).
 * @param headers the stream's HTTP headers (from `behaviorHints.proxyHeaders.request`), for every request mpv makes
 *   for this load: mpv's `http-header-fields`, a `User-Agent` among them.
 * @param startSeconds where the file starts (mpv's `start`); 0 for its beginning.
 * @param demuxerFormat the lavf demuxer the file opens with instead of probing (mpv's `demuxer-lavf-format`): `hls`
 *   when the stream's `proxyHeaders.response` gives an HLS type; null to probe.
 * @param liveStartIndex a live HLS file's first segment, counted back from its playlist's end (negative): lavf's hls
 *   `live_start_index`, as mpv's `demuxer-lavf-o`; null for lavf's own, −3. A rewind in a live window
 *   ([com.edde746.plezy.playback.session.LiveWindow]) reopens the stream with it.
 * @param live the file is known to play live before it opens: the title is a live one, or an earlier open of the file
 *   played live. It goes on after a stall only with a few seconds buffered, and starts so too unless [liveStartIndex]
 *   joins its playlist with the hold-back in hand ([com.edde746.plezy.playback.mpv.MpvLoad.fileProperties]).
 * @param server the server's stream (a media server's file, direct or transcoded, not a live one and not a download):
 *   how the engine reads it over the network ([com.edde746.plezy.playback.mpv.MpvLoad.fileProperties]) and what
 *   the server says of its picture before it opens; null for any other file.
 */
data class LoadRequest(
    val url: String,
    val options: PlaybackOptions,
    val title: String? = null,
    val headers: Map<String, String> = emptyMap(),
    val startSeconds: Double = 0.0,
    val demuxerFormat: String? = null,
    val liveStartIndex: Int? = null,
    val live: Boolean = false,
    val server: ServerStream? = null,
)

/**
 * A media server's stream as the server describes it before it opens ([LoadRequest.server]).
 *
 * @param transcode the server transcodes it (HLS); false for direct play.
 * @param container / [bitrateKbps] the version's container (`mkv`, or lavf's alias list `mov,mp4,m4a,3gp,3g2,mj2`)
 *   and total bitrate, where the server says.
 * @param frameRate / [colorTransfer] the source video's frame rate and transfer (`smpte2084`, `arib-std-b67`, `bt709`)
 *   for direct play; null for a transcode, whose picture the server may change (a tone-mapped HDR source).
 * @param width / [height] the source video's size for direct play; null for a transcode, which the server may scale.
 */
data class ServerStream(
    val transcode: Boolean,
    val container: String? = null,
    val bitrateKbps: Int? = null,
    val frameRate: Double? = null,
    val colorTransfer: String? = null,
    val width: Int? = null,
    val height: Int? = null,
)

enum class TrackKind { VIDEO, AUDIO, SUBTITLE }

/**
 * One entry of mpv's `track-list`.
 * @param selected the track plays: the audio and video, the first subtitle (`sid`).
 * @param secondary the subtitle track shown as the second subtitle (`secondary-sid`).
 * @param isDefault / [forced] / [hearingImpaired] / [visualImpaired] the container flags (`default`, `forced`,
 *   `hearing-impaired`, `visual-impaired`: an audio description of the picture).
 * @param channels the audio channel count (`demux-channel-count`), e.g. 6 for 5.1; null when unknown or not audio.
 * @param codecProfile the codec's profile as FFmpeg names it (`codec-profile`): "Main 10", "High", "LC", "DTS-HD MA",
 *   "Dolby TrueHD + Dolby Atmos", "DTS-HD MA + DTS:X"; null when the container or codec doesn't say.
 * @param externalFilename the file an [external] track was added from (`external-filename`), as the engine got it.
 */
data class Track(
    val id: Long,
    val kind: TrackKind,
    val title: String?,
    val language: String?,
    val codec: String?,
    val selected: Boolean,
    val external: Boolean,
    val isDefault: Boolean = false,
    val forced: Boolean = false,
    val hearingImpaired: Boolean = false,
    val visualImpaired: Boolean = false,
    val channels: Int? = null,
    val codecProfile: String? = null,
    val secondary: Boolean = false,
    val externalFilename: String? = null,
)

enum class DynamicRange { SDR, HDR10, HLG, DOLBY_VISION }

/** The video being shown, once the output is configured (mpv `video-params`, plus the track's Dolby Vision profile). */
data class VideoInfo(
    val width: Int,
    val height: Int,
    val codec: String?,
    val fps: Double?,
    val dynamicRange: DynamicRange,
    /** Dolby Vision profile (5, 7, 8…) when [dynamicRange] is [DynamicRange.DOLBY_VISION]. */
    val doviProfile: Int? = null,
    /**
     * The turn the picture shows with, in degrees clockwise (`video-params/rotate`: a phone's upright video kept
     * sideways).
     */
    val rotation: Int = 0,
    /** The frames' peak over SDR white (`video-params/sig-peak`: above 1 for PQ and HLG); null where mpv says none. */
    val sigPeak: Double? = null,
    /** The colour tags of `video-params` as mpv names them: `gamma` (`pq`, `hlg`, `bt.1886`…), `primaries`, `colormatrix`. */
    val gamma: String? = null,
    val primaries: String? = null,
    val colorMatrix: String? = null,
)

/** The audio being played (mpv `audio-params` and the codec of the selected track). */
data class AudioInfo(
    val codec: String?,
    val channels: Int?,
    val sampleRate: Int?,
)

/**
 * The playback info's details beyond the rest of [EngineState], read while the info shows
 * ([PlayerEngine.setStatsWanted]); in mpv's names and units, formatted by the shared code. A null field is one mpv (or
 * the platform) has no value for at the moment: mpv's bitrates, for one, need a few packets after a load or a seek.
 *
 * @param fileName mpv `filename`: the file's name from its path or URL, percent-encoding undone.
 * @param fileFormat mpv `file-format`, the demuxer's name for the container: "mkv", "mov,mp4,m4a,3gp,3g2,mj2", "hls",
 *   "mpegts".
 * @param fileSizeBytes mpv `file-size`; null for a live stream or a server that doesn't say.
 * @param pixelFormat `video-params/pixelformat`: the decoded frames' format ("yuv420p10", "nv12"), or the kind of
 *   hardware frame ("videotoolbox", "mediacodec", "d3d11") whose own format is [hwPixelFormat].
 * @param hwPixelFormat `video-params/hw-pixelformat`: the format inside hardware frames ("p010", "nv12"); null for
 *   software frames and where the decoder doesn't say (Android's MediaCodec).
 * @param primaries `video-params/primaries` ("bt.2020", "bt.709", "display-p3").
 * @param transfer `video-params/gamma` ("pq", "hlg", "bt.1886").
 * @param colorMatrix `video-params/colormatrix` ("bt.2020-ncl", "bt.709", "dolbyvision").
 * @param maxCll / [maxFall] the content light levels in cd/m² (`video-params/max-cll`, `max-fall`): HDR10 metadata.
 * @param masteringMinLuminance / [masteringMaxLuminance] the mastering display's luminance range in cd/m²
 *   (`video-params/min-luma`, `max-luma`): HDR10 metadata.
 * @param videoBitrate / [audioBitrate] bits per second over the latest packets (`video-bitrate`, `audio-bitrate`).
 * @param droppedFrames frames the video output dropped to keep up (`frame-drop-count`).
 * @param decoderDroppedFrames frames the decoder skipped (`decoder-frame-drop-count`).
 * @param delayedFrames frames shown late (`vo-delayed-frame-count`).
 * @param displayWidth / [displayHeight] / [displayRefreshRate] the display's mode in pixels and Hz, as the platform
 *   or mpv (`display-width`, `display-height`, `display-fps`) reports it.
 * @param channelLayout `audio-params/hr-channels`, the decoded audio's channel layout ("7.1", "5.1(side)", "stereo").
 * @param audioOutput mpv `current-ao`, the audio output driver ("coreaudio", "audiotrack", "wasapi").
 * @param passthroughFormat the compressed format going to the receiver undecoded: `audio-out-params/format` without
 *   its `spdif-` ("truehd", "eac3", "dtshd"); null while the audio is decoded.
 * @param audioRendering how the system renders the audio it plays, where the platform says (Apple's audio session on
 *   iOS and tvOS); null where it doesn't, and while the system doesn't know: it knows only for routes it renders
 *   itself (headphones, AirPlay, CarPlay), not for HDMI.
 * @param cacheBytes `demuxer-cache-state/fw-bytes`: bytes buffered ahead of the position.
 * @param downloadBytesPerSecond mpv `cache-speed`: bytes per second coming in.
 * @param bufferingPercent mpv `cache-buffering-state` (0–100): how much of what playback waits for has arrived.
 * @param estimatedFps mpv `estimated-vf-fps`: the frame rate the video output gets.
 * @param aspectName `video-params/aspect-name` ("16:9", "2.39:1"); null where the shape has no common name.
 * @param avSyncChange mpv `total-avsync-change` in seconds: the A/V sync correction so far.
 * @param sourceSampleRate / [sourceChannelCount] the audio track's own (`current-tracks/audio/demux-samplerate`,
 *   `demux-channel-count`): what a passthrough carrier hides.
 * @param demuxerMaxBytes / [demuxerMaxBackBytes] mpv's forward and back demuxer cache bounds.
 * @param dolbyVision what decodes a Dolby Vision file, on Android; null for other files and elsewhere.
 */
data class PlaybackStats(
    val fileName: String? = null,
    val fileFormat: String? = null,
    val fileSizeBytes: Long? = null,
    val pixelFormat: String? = null,
    val hwPixelFormat: String? = null,
    val primaries: String? = null,
    val transfer: String? = null,
    val colorMatrix: String? = null,
    val maxCll: Double? = null,
    val maxFall: Double? = null,
    val masteringMinLuminance: Double? = null,
    val masteringMaxLuminance: Double? = null,
    val videoBitrate: Double? = null,
    val audioBitrate: Double? = null,
    val droppedFrames: Long? = null,
    val decoderDroppedFrames: Long? = null,
    val delayedFrames: Long? = null,
    val displayWidth: Int? = null,
    val displayHeight: Int? = null,
    val displayRefreshRate: Double? = null,
    val channelLayout: String? = null,
    val audioOutput: String? = null,
    val passthroughFormat: String? = null,
    val audioRendering: AudioRendering? = null,
    val cacheBytes: Long? = null,
    val downloadBytesPerSecond: Long? = null,
    val bufferingPercent: Int? = null,
    val estimatedFps: Double? = null,
    val aspectName: String? = null,
    val avSyncChange: Double? = null,
    val sourceSampleRate: Int? = null,
    val sourceChannelCount: Int? = null,
    val demuxerMaxBytes: Long? = null,
    val demuxerMaxBackBytes: Long? = null,
    val dolbyVision: DolbyVisionStats? = null,
)

/**
 * How a Dolby Vision file decodes on Android ([PlaybackStats.dolbyVision]).
 *
 * @param sourceProfile the bitstream's Dolby Vision profile (its DOVI record).
 * @param route mpv's route ([DolbyVisionRoute]).
 */
data class DolbyVisionStats(
    val sourceProfile: Int? = null,
    val route: DolbyVisionRoute? = null,
)

/** What decodes a Dolby Vision file on Android mpv; [id] is mpv-android's `GpuVoPolicy.DvRoute` id. */
enum class DolbyVisionRoute(val id: String) {
    /** The Dolby Vision MediaCodec decoder takes the stream as it is. */
    DV_DECODER("dv-decoder"),

    /** Profile 7 converted to 8.1 for a profile 8 Dolby Vision decoder. */
    DV_DECODER_P81("dv-decoder-p81"),

    /** No Dolby Vision decoder: the base layer decodes on its own. */
    BASE_LAYER("base-layer"),

    /** Software decode on gpu-next, which applies the RPU itself. */
    RESHAPED("reshaped"),
    ;

    companion object {
        /** Null for an absent or unknown id. */
        fun of(id: String?): DolbyVisionRoute? = entries.firstOrNull { it.id == id }
    }
}

/** How the system renders the audio it plays ([PlaybackStats.audioRendering]): Apple's audio session rendering modes. */
enum class AudioRendering { STEREO, SURROUND, SPATIAL_AUDIO, DOLBY_AUDIO, DOLBY_ATMOS }

data class Chapter(val title: String?, val startSeconds: Double)

/**
 * Why the engine stopped the file. [kind] (or [httpStatus]) is what the player says; [message] is the engine's own
 * English text (mpv's error string, a log line), which goes to the log and never into the interface.
 */
data class EngineError(val message: String, val httpStatus: Int? = null, val kind: EngineErrorKind = EngineErrorKind.OTHER)

/**
 * What went wrong in the engine, as the player words it ([PlaybackFailure.displayText]). mpv's error codes map to it in
 * [com.edde746.plezy.playback.mpv.MpvState.errorKind], one rule for every engine.
 */
enum class EngineErrorKind {
    /** The stream couldn't be opened or read: mpv's "loading failed". */
    OPEN,

    /** No demuxer reads the file, or mpv doesn't support what it holds. */
    FORMAT,

    /** The file opened, but its video or audio didn't play: no track decoded, an output failed, decoding stalled. */
    DECODE,

    /** Anything else: mpv failing to start, a command it refused. */
    OTHER,

    /**
     * The audio device stopped taking audio (mpv's audio output failed to open): the device's fault, not the stream's,
     * so nothing about the stream is tried again.
     */
    AUDIO_OUTPUT,

    /**
     * The stream stopped before the video's end: the file ended after an HTTP error, or well before its length, as the
     * playback session judges it.
     */
    CUT_SHORT,
}

data class EngineState(
    /**
     * The load ([PlayerEngine.load]'s id) this state is of: everything else in it is that load's file's, or the player's
     * settings. 0 before the first load.
     */
    val loadId: Long = 0,
    val positionSeconds: Double = 0.0,
    /**
     * mpv `duration`; 0 while there is none: from a load until mpv reports the new file's, which can be after its first
     * frame (mpv hands its client queued events, `file-loaded` and `playback-restart`, before property changes).
     */
    val durationSeconds: Double = 0.0,
    val paused: Boolean = false,
    /**
     * The file waits for its picture rather than playing or holding: from [PlayerEngine.load] until its first frame
     * shows, while mpv waits for data (`paused-for-cache`), while a seek is under way (mpv's `seeking`, until its
     * `playback-restart`; not the engine's own seek to where it plays, which a speed change may make) and while the
     * platform holds playback (a display mode switch; Apple's start gate). Never with an [error] or at the end ([eof]),
     * nor once a file failed to open. A pause by the caller doesn't end it (the player shows the pause first).
     * [com.edde746.plezy.playback.mpv.MpvState.buffering] is the rule.
     */
    val buffering: Boolean = false,
    /**
     * Where what the engine has read ahead ends, in the file's seconds, as the position is: mpv's `demuxer-cache-state`
     * `cache-end`, and the file's end ([durationSeconds]) once the read reached it (its `eof`, which a seek elsewhere
     * clears). It only grows while the engine reads on, however late mpv reports it (once it has read the whole file,
     * every second of playback); a seek elsewhere starts it again. Null while nothing is read.
     */
    val cacheEndSeconds: Double? = null,
    /**
     * Where the stretch the engine holds read around the position starts, in the file's seconds (mpv's
     * `demuxer-cache-state`, its `seekable-ranges` entry holding the position): a seek back to it or later lands in
     * what was read, even in a file it can't seek in. Null when no stretch holds the position.
     */
    val cacheStartSeconds: Double? = null,
    val tracks: List<Track> = emptyList(),
    /**
     * The current file has shown its first frame: from mpv's first `playback-restart` after the file started (paused or
     * not) until the next [PlayerEngine.load] or the file ending in an error. The end of the file ([eof]) keeps it.
     */
    val loaded: Boolean = false,
    /**
     * The engine reached the end of the file (mpv's `eof-reached`, or its `end-file` for that reason): what the engine
     * read ended, whether or not the video did. The playback session reports an end it takes for the stream failing
     * as an [error] instead ([EngineErrorKind.CUT_SHORT]).
     */
    val eof: Boolean = false,
    val error: EngineError? = null,
    val speed: Double = 1.0,
    val subtitleDelaySeconds: Double = 0.0,
    val audioDelaySeconds: Double = 0.0,
    val volume: Double = 100.0,
    val muted: Boolean = false,
    val video: VideoInfo? = null,
    /**
     * How the picture goes out, kept current whether or not the playback info shows: an HDR format while the display
     * gets HDR, [DynamicRange.SDR] while it gets SDR (an HDR video then tone-mapped); null until the output is
     * configured, or where neither mpv (`video-target-params/gamma`) nor the platform says.
     */
    val outputDynamicRange: DynamicRange? = null,
    val audio: AudioInfo? = null,
    /** mpv's `hwdec-current`: "no" for software decoding, otherwise the hardware decoder. */
    val hwdec: String? = null,
    val chapters: List<Chapter> = emptyList(),
    /** The outputs mpv can play to (`audio-device-list`), on platforms where the player picks one; empty elsewhere. */
    val audioDevices: List<AudioDevice> = emptyList(),
    /** The output playing (`audio-device`), [AudioDevice.name]; "auto" for the system's choice. */
    val audioDevice: String = "auto",
    /**
     * mpv `seekable`: the file can be seeked (false for some live streams, and before the engine's first file opened).
     * A load keeps the value until mpv reports another, which for the new file can come after its first frame, as its
     * [durationSeconds] can.
     */
    val seekable: Boolean = false,
    /**
     * mpv's `playback-restart` events in the current file: the first once its first frame shows after the load (paused
     * or not), then one after each seek. 0 until the first frame; back to 0 when another file starts loading.
     */
    val playbackRestarts: Int = 0,
    /** The audio goes to the receiver undecoded (passthrough in effect): the speed can't be nudged without a glitch. */
    val audioPassthrough: Boolean = false,
    /**
     * How the system renders the audio now, where the platform says and knows (Apple's audio session on iOS and tvOS
     * 17.2+, for routes it renders itself); null while unknown, never read as "not Dolby".
     */
    val audioRendering: AudioRendering? = null,
    /** The playback info's details while it shows ([PlayerEngine.setStatsWanted]); null otherwise. */
    val stats: PlaybackStats? = null,
    /**
     * The HTTP error status the engine's HTTP client last logged for the current file's stream ("HTTP error 403
     * Forbidden": its open, a seek's or a reconnect's request); null while none. An external subtitle's isn't the
     * stream's. FFmpeg ends a read that failed this way as the file's end, so an [eof] with it is the stream failing.
     */
    val httpErrorStatus: Int? = null,
    /**
     * The current file's stream logged a fault of its transport (FFmpeg's network layer: a connection reset, a read that
     * ended short of the length, a reconnect), latched from the file's start: the fault behind an early end can be
     * minutes older than the end, which the read-ahead plays out.
     */
    val transportFault: Boolean = false,
    /** mpv `file-size` of the current file: the bytes the transport holds the stream to; null for a stream without one. */
    val fileSizeBytes: Long? = null,
    /** mpv `file-format` of the current file, lavf's demuxer names ("matroska,webm", "hls"); null until it opened. */
    val fileFormat: String? = null,
)
