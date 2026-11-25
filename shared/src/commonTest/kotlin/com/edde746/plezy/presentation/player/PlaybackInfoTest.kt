package com.edde746.plezy.presentation.player

import com.edde746.plezy.input.InputKey
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.input.PlayerMenu
import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.AudioInfo
import com.edde746.plezy.playback.AudioRendering
import com.edde746.plezy.playback.DolbyVisionRoute
import com.edde746.plezy.playback.DolbyVisionStats
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.PlaybackStats
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoInfo
import com.edde746.plezy.playback.mpv.MpvState
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class PlaybackInfoTest {
    private fun sections(
        state: EngineState,
        local: Boolean = false,
        transcoding: Boolean? = null,
        memoryBytes: Long? = null,
        uiFps: Double? = null,
    ) = PlaybackInfo.sections(state, local, transcoding, memoryBytes, uiFps, "en")

    @Test
    fun anHdr10HevcRemuxWithTrueHdAtmos() {
        val state = EngineState(
            loaded = true,
            durationSeconds = 8000.0,
            cacheEndSeconds = 42.4,
            tracks = listOf(
                Track(1, TrackKind.VIDEO, null, null, "hevc", selected = true, external = false, codecProfile = "Main 10"),
                Track(1, TrackKind.AUDIO, "TrueHD Atmos 7.1", "eng", "truehd", selected = true, external = false, channels = 8, codecProfile = "Dolby TrueHD + Dolby Atmos"),
                Track(2, TrackKind.AUDIO, "Commentary", "eng", "ac3", selected = false, external = false, channels = 2),
                Track(1, TrackKind.SUBTITLE, null, "eng", "hdmv_pgs_subtitle", selected = true, external = false),
                Track(2, TrackKind.SUBTITLE, null, "fre", "subrip", selected = false, external = true),
            ),
            video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10),
            outputDynamicRange = DynamicRange.HDR10,
            audio = AudioInfo("truehd", 8, 48000),
            hwdec = "videotoolbox",
            stats = PlaybackStats(
                fileName = "Movie.2160p.UHD.BluRay.REMUX.HDR.HEVC.TrueHD.7.1.Atmos.mkv",
                fileFormat = "mkv",
                fileSizeBytes = 62_600_000_000,
                pixelFormat = "videotoolbox",
                hwPixelFormat = "p010",
                primaries = "bt.2020",
                transfer = "pq",
                colorMatrix = "bt.2020-ncl",
                maxCll = 1000.0,
                maxFall = 400.0,
                masteringMinLuminance = 0.005,
                masteringMaxLuminance = 1000.0,
                videoBitrate = 48_512_000.0,
                audioBitrate = 4_210_000.0,
                droppedFrames = 0,
                decoderDroppedFrames = 0,
                delayedFrames = 2,
                displayWidth = 3840,
                displayHeight = 2160,
                displayRefreshRate = 60.0,
                channelLayout = "7.1",
                audioOutput = "coreaudio",
                cacheBytes = 251_658_240,
                downloadBytesPerSecond = 12_897_484,
                bufferingPercent = 100,
                estimatedFps = 23.976,
                aspectName = "16:9",
                avSyncChange = -0.012,
                demuxerMaxBytes = 67_108_864,
                demuxerMaxBackBytes = 33_554_432,
            ),
        )
        assertEquals(
            listOf(
                InfoSection(
                    InfoSectionId.STREAM,
                    "Stream",
                    listOf(
                        InfoRow("File", "Movie.2160p.UHD.BluRay.REMUX.HDR.HEVC.TrueHD.7.1.Atmos.mkv", freeText = true),
                        InfoRow("Container", "MKV"),
                        InfoRow("Size", "58.3 GB"),
                        InfoRow("Bitrate", "62.6 Mb/s"),
                    ),
                ),
                InfoSection(
                    InfoSectionId.VIDEO,
                    "Video",
                    listOf(
                        InfoRow("Codec", "HEVC Main 10"),
                        InfoRow("Resolution", "3840×2160 · 23.976 fps"),
                        InfoRow("Dynamic range", "HDR10"),
                        InfoRow("Bitrate", "48.5 Mb/s"),
                        InfoRow("Decoder", "Hardware (VideoToolbox)"),
                        InfoRow("Aspect", "16:9"),
                        InfoRow("Output", "3840×2160 · 60 Hz · HDR10"),
                    ),
                ),
                InfoSection(
                    InfoSectionId.COLOR,
                    "Color",
                    listOf(
                        InfoRow("Pixel format", "10-bit · 4:2:0"),
                        InfoRow("Primaries", "BT.2020"),
                        InfoRow("Transfer", "PQ"),
                        InfoRow("Matrix", "BT.2020 NCL"),
                    ),
                ),
                InfoSection(
                    InfoSectionId.HDR,
                    "HDR",
                    listOf(InfoRow("Mastering display", "0.005–1,000 nits"), InfoRow("MaxCLL / MaxFALL", "1,000 / 400 nits")),
                ),
                InfoSection(
                    InfoSectionId.AUDIO,
                    "Audio",
                    listOf(
                        InfoRow("Codec", "TrueHD Atmos"),
                        InfoRow("Channels", "7.1"),
                        InfoRow("Sample rate", "48 kHz"),
                        InfoRow("Bitrate", "4.2 Mb/s"),
                        InfoRow("Track", "English · \u2068TrueHD Atmos 7.1\u2069", freeText = true),
                        InfoRow("Output", "Core Audio", freeText = true),
                    ),
                ),
                InfoSection(
                    InfoSectionId.SUBTITLES,
                    "Subtitles",
                    listOf(InfoRow("Track", "English", freeText = true), InfoRow("Format", "PGS · Embedded")),
                ),
                InfoSection(
                    InfoSectionId.PERFORMANCE,
                    "Performance",
                    listOf(
                        InfoRow("Render FPS", "23.98"),
                        InfoRow("A/V sync", "−12 ms"),
                        InfoRow("Dropped frames", "0 (decoder 0)"),
                        InfoRow("Delayed frames", "2"),
                        InfoRow("UI FPS", "59.9"),
                    ),
                ),
                InfoSection(
                    InfoSectionId.APP,
                    "App",
                    listOf(InfoRow("Play method", "Direct Play"), InfoRow("Memory", "512 MB")),
                ),
                InfoSection(
                    InfoSectionId.BUFFER,
                    "Buffer",
                    listOf(InfoRow("Cache", "42 s · 240 MB"), InfoRow("Cache limit", "96 MB"), InfoRow("Download speed", "12.3 MB/s")),
                ),
            ),
            sections(state, transcoding = false, memoryBytes = 512L * 1024 * 1024, uiFps = 59.94),
        )
    }

    /** mpv's file name of a stream URL keeps its query, and is the whole URL when the path ends in `/`. */
    @Test
    fun theFileRowShowsNothingOfTheLinkButTheFileName() {
        fun fileRow(fileName: String) = sections(EngineState(loaded = true, stats = PlaybackStats(fileName = fileName)))
            .firstOrNull { it.id == InfoSectionId.STREAM }?.rows?.singleOrNull { it.label == "File" }?.value
        assertEquals("Example.Film.mkv", fileRow("Example.Film.mkv?token=s3cr3t&k=fakeApiKey42"))
        assertEquals(null, fileRow("https://cdn.example.com/dl/fakeApiKey42/"))
    }

    @Test
    fun aDolbyVisionDownloadOnAndroidWithAtmosPassthrough() {
        val state = EngineState(
            loaded = true,
            durationSeconds = 3000.0,
            tracks = listOf(
                Track(1, TrackKind.VIDEO, null, null, "hevc", selected = true, external = false, codecProfile = "Main 10"),
                Track(1, TrackKind.AUDIO, null, "eng", "eac3", selected = true, external = false, channels = 6, codecProfile = "Dolby Digital Plus + Dolby Atmos"),
            ),
            video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.DOLBY_VISION, doviProfile = 8),
            outputDynamicRange = DynamicRange.HDR10,
            audio = AudioInfo("eac3", 2, 192000),
            hwdec = "mediacodec",
            audioPassthrough = true,
            stats = PlaybackStats(
                fileName = "Show.S01E01.2160p.WEB-DL.DV.mkv",
                fileFormat = "mkv",
                fileSizeBytes = 4_831_838_208,
                pixelFormat = "mediacodec",
                primaries = "bt.2020",
                transfer = "pq",
                colorMatrix = "bt.2020-ncl",
                videoBitrate = 15_120_000.0,
                audioBitrate = 768_000.0,
                droppedFrames = 3,
                decoderDroppedFrames = 1,
                delayedFrames = 0,
                displayWidth = 2400,
                displayHeight = 1080,
                displayRefreshRate = 90.0,
                channelLayout = "stereo",
                audioOutput = "audiotrack",
                passthroughFormat = "eac3",
                sourceSampleRate = 48000,
                sourceChannelCount = 6,
                dolbyVision = DolbyVisionStats(sourceProfile = 8, route = DolbyVisionRoute.DV_DECODER),
            ),
        )
        val sections = sections(state, local = true)
        assertEquals(
            listOf(InfoSectionId.STREAM, InfoSectionId.VIDEO, InfoSectionId.COLOR, InfoSectionId.AUDIO, InfoSectionId.PERFORMANCE),
            sections.map { it.id },
            "a download has no play method and no buffer",
        )
        assertEquals(
            listOf(
                InfoRow("Source", "Downloaded"),
                InfoRow("File", "Show.S01E01.2160p.WEB-DL.DV.mkv", freeText = true),
                InfoRow("Container", "MKV"),
                InfoRow("Size", "4.5 GB"),
                InfoRow("Bitrate", "12.9 Mb/s"),
            ),
            sections[0].rows,
        )
        assertEquals(
            listOf(
                InfoRow("Codec", "HEVC Main 10"),
                InfoRow("Resolution", "3840×2160 · 23.976 fps"),
                InfoRow("Dynamic range", "Dolby Vision profile 8"),
                InfoRow("Bitrate", "15.1 Mb/s"),
                InfoRow("Decoder", "Hardware (MediaCodec)"),
                InfoRow("Dolby Vision path", "Dolby Vision decoder"),
                InfoRow("Output", "2400×1080 · 90 Hz · HDR10"),
            ),
            sections[1].rows,
        )
        // MediaCodec says nothing of its frames' format: the profile names the depth.
        assertEquals(InfoRow("Pixel format", "10-bit"), sections[2].rows.first())
        assertEquals(
            listOf(
                InfoRow("Codec", "E-AC3 Atmos"),
                InfoRow("Channels", "5.1"),
                InfoRow("Sample rate", "48 kHz"),
                InfoRow("Bitrate", "768 kb/s"),
                InfoRow("Track", "English", freeText = true),
                InfoRow("Output", "AudioTrack · Passthrough (E-AC3)", freeText = true),
            ),
            sections[3].rows,
            "passed through, the track's own channels and rate, not the carrier's 192 kHz stereo",
        )
        assertEquals(
            listOf(
                InfoRow("Render FPS", "—"),
                InfoRow("A/V sync", "—"),
                InfoRow("Dropped frames", "3 (decoder 1)"),
                InfoRow("Delayed frames", "0"),
                InfoRow("UI FPS", "—"),
            ),
            sections[4].rows,
        )
    }

    @Test
    fun aDtsHdMaTrackOnWindowsWithAPickedOutput() {
        val state = EngineState(
            loaded = true,
            durationSeconds = 10.016,
            tracks = listOf(
                Track(1, TrackKind.VIDEO, null, null, "h264", selected = true, external = false, codecProfile = "High"),
                Track(1, TrackKind.AUDIO, "DTS-HD MA 7.1", "eng", "dts", selected = true, external = false, channels = 8, codecProfile = "DTS-HD MA"),
            ),
            video = VideoInfo(1920, 1080, "h264", 23.976, DynamicRange.SDR),
            outputDynamicRange = DynamicRange.SDR,
            audio = AudioInfo("dts", 2, 192000),
            hwdec = "d3d11va-copy",
            audioDevices = listOf(AudioDevice("auto", "Autoselect device"), AudioDevice("wasapi/{1}", "Speakers (Realtek(R) Audio)")),
            audioDevice = "wasapi/{1}",
            stats = PlaybackStats(
                fileName = "dts-hdma.mkv",
                fileFormat = "mkv",
                fileSizeBytes = 5_376_581,
                pixelFormat = "nv12",
                primaries = "bt.709",
                transfer = "bt.1886",
                colorMatrix = "bt.709",
                displayWidth = 2560,
                displayHeight = 1440,
                displayRefreshRate = 59.94,
                channelLayout = "stereo",
                audioOutput = "wasapi",
                passthroughFormat = "dtshd",
                sourceSampleRate = 48000,
                sourceChannelCount = 8,
            ),
        )
        val sections = sections(state)
        assertEquals(
            listOf(
                InfoRow("Codec", "H.264 High"),
                InfoRow("Resolution", "1920×1080 · 23.976 fps"),
                InfoRow("Dynamic range", "SDR"),
                InfoRow("Bitrate", "—"),
                InfoRow("Decoder", "Hardware (D3D11VA copy)"),
                InfoRow("Output", "2560×1440 · 59.94 Hz · SDR"),
            ),
            sections.single { it.id == InfoSectionId.VIDEO }.rows,
            "a live value mpv has none for yet keeps its row",
        )
        assertEquals(
            listOf(InfoRow("Pixel format", "8-bit · 4:2:0"), InfoRow("Primaries", "BT.709"), InfoRow("Transfer", "BT.1886"), InfoRow("Matrix", "BT.709")),
            sections.single { it.id == InfoSectionId.COLOR }.rows,
        )
        assertEquals(
            listOf(
                InfoRow("Codec", "DTS-HD MA"),
                InfoRow("Channels", "7.1"),
                InfoRow("Sample rate", "48 kHz"),
                InfoRow("Bitrate", "—"),
                InfoRow("Track", "English · \u2068DTS-HD MA 7.1\u2069", freeText = true),
                InfoRow("Output", "\u2068Speakers (Realtek(R) Audio)\u2069 · WASAPI · Passthrough (DTS-HD)", freeText = true),
            ),
            sections.single { it.id == InfoSectionId.AUDIO }.rows,
        )
        assertEquals(InfoRow("Bitrate", "4.3 Mb/s"), sections.single { it.id == InfoSectionId.STREAM }.rows.last())
        assertEquals("DTS-HD MA + DTS:X", CodecNames.audio("dts", "DTS-HD MA + DTS:X"))
        assertEquals("DTS", CodecNames.audio("dts", null))
    }

    @Test
    fun theSelectedTrackFillsInWhatAudioParamsDoesNotReport() {
        val state = EngineState(
            loaded = true,
            tracks = listOf(Track(1, TrackKind.AUDIO, null, "eng", "eac3", selected = true, external = false, channels = 6)),
            audio = AudioInfo(null, null, 44100),
        )
        assertEquals(
            listOf(InfoRow("Codec", "E-AC3"), InfoRow("Channels", "5.1"), InfoRow("Sample rate", "44.1 kHz"), InfoRow("Track", "English", freeText = true)),
            sections(state).single { it.id == InfoSectionId.AUDIO }.rows,
        )
    }

    @Test
    fun planarRgbFormatsReadAsTheirDepthWithoutSubsampling() {
        assertEquals(CodecNames.PixelFormat(8, null), CodecNames.pixelFormat("gbrp"))
        assertEquals(CodecNames.PixelFormat(10, null), CodecNames.pixelFormat("gbrp10le"))
        assertEquals(CodecNames.PixelFormat(12, null), CodecNames.pixelFormat("gbrap12"))
        assertEquals(CodecNames.PixelFormat(10, "4:2:0"), CodecNames.pixelFormat("yuv420p10"))
    }

    @Test
    fun aStereoAacWebFileStillBuffering() {
        val state = EngineState(
            loaded = true,
            buffering = true,
            durationSeconds = 0.0,
            cacheEndSeconds = 1.6,
            tracks = listOf(
                Track(1, TrackKind.VIDEO, null, null, "h264", selected = true, external = false, codecProfile = "High"),
                Track(1, TrackKind.AUDIO, null, null, "aac", selected = true, external = false, channels = 2, codecProfile = "LC"),
            ),
            video = VideoInfo(1920, 1080, "h264", 25.0, DynamicRange.SDR),
            audio = AudioInfo("aac", 2, 44100),
            hwdec = "no",
            stats = PlaybackStats(
                fileName = "index.m3u8",
                fileFormat = "hls,applehttp",
                pixelFormat = "yuv420p",
                primaries = "bt.709",
                transfer = "bt.1886",
                colorMatrix = "bt.709",
                audioBitrate = 128_000.0,
                droppedFrames = 0,
                decoderDroppedFrames = 0,
                delayedFrames = 0,
                channelLayout = "stereo",
                audioOutput = "pipewire",
                cacheBytes = 524_288,
                downloadBytesPerSecond = 4 * 1024 * 1024,
                bufferingPercent = 45,
            ),
        )
        val sections = sections(state, transcoding = true)
        assertEquals(
            listOf(InfoRow("File", "index.m3u8", freeText = true), InfoRow("Container", "HLS")),
            sections.single { it.id == InfoSectionId.STREAM }.rows,
            "a live stream has no size, so no overall bitrate",
        )
        assertEquals(
            listOf(
                InfoRow("Codec", "H.264 High"),
                InfoRow("Resolution", "1920×1080 · 25 fps"),
                InfoRow("Dynamic range", "SDR"),
                InfoRow("Bitrate", "—"),
                InfoRow("Decoder", "Software"),
            ),
            sections.single { it.id == InfoSectionId.VIDEO }.rows,
            "no output row where the platform reports none",
        )
        assertEquals(
            listOf(
                InfoRow("Codec", "AAC LC"),
                InfoRow("Channels", "Stereo"),
                InfoRow("Sample rate", "44.1 kHz"),
                InfoRow("Bitrate", "128 kb/s"),
                InfoRow("Track", "Track 1", freeText = true),
                InfoRow("Output", "PipeWire", freeText = true),
            ),
            sections.single { it.id == InfoSectionId.AUDIO }.rows,
        )
        assertEquals(listOf(InfoRow("Play method", "Transcoding")), sections.single { it.id == InfoSectionId.APP }.rows)
        assertEquals(
            listOf(InfoRow("Cache", "2 s · 512 KB"), InfoRow("Download speed", "4.0 MB/s"), InfoRow("Buffering", "45%")),
            sections.single { it.id == InfoSectionId.BUFFER }.rows,
        )
        assertEquals(InfoSectionId.BUFFER, sections.last().id, "the rows that come and go are last")
    }

    // What mpv reports, as each engine reads it ([MpvState.stats]).

    /** The sections where mpv answers [properties] (as text, and as numbers where they parse). */
    private fun mpv(properties: Map<String, String>, audio: AudioInfo? = null, dolbyVision: DolbyVisionStats? = null): List<InfoSection> {
        val stats = MpvState.stats(text = { properties[it] }, number = { properties[it]?.toDoubleOrNull() }, display = null)
            .copy(dolbyVision = dolbyVision)
        return sections(EngineState(loaded = true, audio = audio, stats = stats))
    }

    @Test
    fun withoutTheTracksOwnFiguresPassthroughShowsNoneRatherThanTheCarriers() {
        val audio = mpv(
            mapOf("audio-out-params/format" to "spdif-dts-hd", "audio-params/hr-channels" to "stereo"),
            audio = AudioInfo("dts", 2, 192000),
        ).single { it.id == InfoSectionId.AUDIO }.rows
        assertNull(audio.firstOrNull { it.label == "Sample rate" }, "no 192 kHz")
        assertNull(audio.firstOrNull { it.label == "Channels" }, "no stereo")
        assertEquals(InfoRow("Output", "Passthrough (DTS-HD)", freeText = true), audio.last())
    }

    @Test
    fun locallyDecodedAudioKeepsMpvsAudioParams() {
        val audio = mpv(
            mapOf(
                "audio-out-params/format" to "floatp",
                "audio-params/hr-channels" to "5.1",
                "current-tracks/audio/demux-samplerate" to "44100",
                "current-tracks/audio/demux-channel-count" to "8",
            ),
            audio = AudioInfo("eac3", 6, 48000),
        ).single { it.id == InfoSectionId.AUDIO }.rows
        assertEquals(listOf(InfoRow("Codec", "E-AC3"), InfoRow("Channels", "5.1"), InfoRow("Sample rate", "48 kHz")), audio.take(3))
    }

    /** mpv's `cache-used` went with its stream cache; the bytes ahead are `demuxer-cache-state`'s `fw-bytes`. */
    @Test
    fun theCacheIsTheFwBytesOfDemuxerCacheState() {
        fun cache(state: String?) = mpv(listOfNotNull(state?.let { "demuxer-cache-state" to it }).toMap())
            .single { it.id == InfoSectionId.BUFFER }.rows.single { it.label == "Cache" }.value
        assertEquals("12.0 MB", cache("""{"fw-bytes":12582912,"total-bytes":20971520,"eof":false}"""))
        val verbatim =
            """{"cache-end":5.960000,"reader-pts":0.360000,"cache-duration":5.600000,"eof":true,""" +
                """"underrun":false,"idle":true,"total-bytes":376864,"fw-bytes":347648,""" +
                """"raw-input-rate":2481023,"debug-low-level-seeks":0,"debug-byte-level-seeks":1,""" +
                """"debug-ts-last":5.990748,"ts-per-stream":[{"type":"video","cache-duration":5.600000,""" +
                """"reader-pts":0.360000,"cache-end":5.960000},{"type":"audio","cache-duration":5.804989,""" +
                """"reader-pts":0.185760,"cache-end":5.990748}],"bof-cached":true,"eof-cached":true,""" +
                """"seekable-ranges":[{"start":-0.023220,"end":5.990748}]}"""
        assertEquals("340 KB", cache(verbatim), "mpv's own serialisation, nested arrays and all")
        assertEquals("—", cache(null))
        for (blob in listOf("""{"fw-bytes":""", "not json at all", "[]", """{"total-bytes":20971520}""", """{"fw-bytes":"lots"}""")) {
            assertEquals("—", cache(blob), blob)
        }
    }

    /** The back cache takes forward bytes the reader hasn't claimed, so the ceiling is the forward plus the back bound. */
    @Test
    fun theCacheLimitIsTheForwardPlusTheBackBound() {
        fun limit(properties: Map<String, String>) =
            mpv(properties).single { it.id == InfoSectionId.BUFFER }.rows.firstOrNull { it.label == "Cache limit" }?.value
        assertEquals("96 MB", limit(mapOf("demuxer-max-bytes" to "67108864", "demuxer-max-back-bytes" to "33554432")))
        assertEquals("64 MB", limit(mapOf("demuxer-max-bytes" to "67108864")))
        assertNull(limit(emptyMap()))
    }

    @Test
    fun theRenderRateAndTheAvSyncAreMpvsOwnMeasures() {
        fun performance(properties: Map<String, String>) = mpv(properties).single { it.id == InfoSectionId.PERFORMANCE }.rows.take(2).map { it.value }
        assertEquals(listOf("23.98", "−12 ms"), performance(mapOf("estimated-vf-fps" to "23.976", "total-avsync-change" to "-0.012")))
        assertEquals(listOf("59.94", "+5 ms"), performance(mapOf("estimated-vf-fps" to "59.94", "total-avsync-change" to "0.0049")))
        assertEquals(listOf("—", "0 ms"), performance(mapOf("total-avsync-change" to "0.0001")))
    }

    // The Dolby Vision route, as Android's mpv engine reports it.

    private fun dolbyVisionPath(gamma: String?, route: String): String? {
        val properties = if (gamma == null) emptyMap() else mapOf("video-params" to """{"pixelformat":"mediacodec","w":3840,"h":2160,"gamma":"$gamma"}""")
        val stats = MpvState.stats(text = { properties[it] }, number = { null }, display = null)
            .copy(dolbyVision = DolbyVisionStats(sourceProfile = 8, route = DolbyVisionRoute.of(route)))
        val state = EngineState(loaded = true, video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.DOLBY_VISION), stats = stats)
        val video = sections(state).single { it.id == InfoSectionId.VIDEO }.rows
        assertEquals(InfoRow("Dynamic range", "Dolby Vision profile 8"), video.single { it.label == "Dynamic range" }, "the decoder's profile")
        return video.firstOrNull { it.label == "Dolby Vision path" }?.value
    }

    @Test
    fun aBaseLayerIsNamedByTheTransferItDecodesToSoAP81FallbackReadsAsHdr10() {
        val cases = mapOf(
            "pq" to "HDR10 base layer",
            "hlg" to "HLG base layer",
            "bt.1886" to "SDR base layer",
            "auto" to "Base layer",
            null to "Base layer",
        )
        for ((gamma, label) in cases) assertEquals(label, dolbyVisionPath(gamma, "base-layer"), "gamma=$gamma")
        assertEquals("Dolby Vision decoder", dolbyVisionPath("pq", "dv-decoder"), "the decoder isn't named by the transfer")
    }

    @Test
    fun anUnknownRouteOrNoDoviRecordShowsNoPath() {
        assertNull(dolbyVisionPath("pq", "teleported"))
        val plain = sections(EngineState(loaded = true, video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10), stats = PlaybackStats(transfer = "pq")))
        assertNull(plain.single { it.id == InfoSectionId.VIDEO }.rows.firstOrNull { it.label == "Dolby Vision path" })
    }

    @Test
    fun aTurnedVideoSaysByHowMuch() {
        val video = sections(EngineState(loaded = true, video = VideoInfo(1080, 1920, "h264", 30.0, DynamicRange.SDR, rotation = 90)))
            .single { it.id == InfoSectionId.VIDEO }.rows
        assertEquals(InfoRow("Rotation", "90°"), video.last())
    }

    @Test
    fun bitratesAndSpeedsKeepTheirShape() {
        assertEquals("640 kb/s", PlaybackInfo.bitrate(640_000.0))
        assertEquals("999 kb/s", PlaybackInfo.bitrate(999_400.0))
        assertEquals("1.0 Mb/s", PlaybackInfo.bitrate(999_960.0))
        assertEquals("120.0 Mb/s", PlaybackInfo.bitrate(120_000_000.0))
        assertEquals("512 B/s", PlaybackInfo.speed(512))
        assertEquals("2.0 MB/s", PlaybackInfo.speed(2 * 1024 * 1024))
        assertEquals("150 MB/s", PlaybackInfo.speed(150L * 1024 * 1024))
    }

    /**
     * The system's rendering of the audio (Apple's audio session) is the Audio section's last row, by Apple's name for
     * it; where the platform reports none (Android, desktop, a route the system doesn't render itself) there is no row.
     */
    @Test
    fun theSystemsRenderingShowsWhereThePlatformReportsIt() {
        fun rendering(rendering: AudioRendering?): String? {
            val state = EngineState(
                loaded = true,
                audio = AudioInfo("truehd", 6, 48000),
                stats = PlaybackStats(audioOutput = "avfoundation", audioRendering = rendering),
            )
            val audio = sections(state).first { it.id == InfoSectionId.AUDIO }.rows
            return audio.last().takeIf { it.label == "Rendering" }?.value
        }
        assertEquals("Dolby Atmos", rendering(AudioRendering.DOLBY_ATMOS))
        assertEquals("Dolby Audio", rendering(AudioRendering.DOLBY_AUDIO))
        assertEquals("Spatial Audio", rendering(AudioRendering.SPATIAL_AUDIO))
        assertEquals("Surround", rendering(AudioRendering.SURROUND))
        assertEquals("Stereo", rendering(AudioRendering.STEREO))
        assertEquals(null, rendering(null))
    }

    @Test
    fun columnsTakeSectionsInOrderWhereTheyAreShortest() {
        fun section(id: InfoSectionId, rows: Int) = InfoSection(id, id.name, List(rows) { InfoRow("$it", "") })
        val sections = listOf(
            section(InfoSectionId.STREAM, 7),
            section(InfoSectionId.VIDEO, 12),
            section(InfoSectionId.AUDIO, 6),
            section(InfoSectionId.SUBTITLES, 2),
            section(InfoSectionId.BUFFER, 2),
        )
        fun ids(columns: Int) = InfoColumns.split(sections, columns).map { column -> column.map { it.id } }
        assertEquals(listOf(sections.map { it.id }), ids(1))
        assertEquals(
            listOf(
                listOf(InfoSectionId.STREAM, InfoSectionId.AUDIO, InfoSectionId.BUFFER),
                listOf(InfoSectionId.VIDEO, InfoSectionId.SUBTITLES),
            ),
            ids(2),
        )
        assertEquals(
            listOf(
                listOf(InfoSectionId.STREAM, InfoSectionId.BUFFER),
                listOf(InfoSectionId.VIDEO),
                listOf(InfoSectionId.AUDIO, InfoSectionId.SUBTITLES),
            ),
            ids(3),
        )
        assertEquals(ids(2), InfoColumns.split(sections.dropLast(1) + section(InfoSectionId.BUFFER, 3), 2).map { c -> c.map { it.id } }, "the buffer's own rows move nothing")
        assertEquals(3, InfoColumns.split(sections.take(3), 5).size, "no empty columns")
    }

    // The player.

    /**
     * The playback info is one switch for every player to come: the options' Show playback info, a remote's Info key
     * and the menus' entry flip it, and this device keeps it. The engine reads its stats only while the card shows:
     * auto-hide (on by default) fades it with the controls, picture in picture takes it away.
     */
    @Test
    fun theSwitchIsKeptAndTheEngineReadsWhileTheCardShows() = playerTest {
        playing()
        assertNull(state.playbackInfo)
        assertEquals(false, state.options.single { it.id == PlayerOptionId.PLAYBACK_INFO }.on)
        assertEquals(emptyList(), engine.statsWanted, "nothing is read before it is on")

        dispatch(PlayerCommand.OpenMenu(PlayerMenu.OPTIONS))
        dispatch(state.options.single { it.id == PlayerOptionId.PLAYBACK_INFO }.toggle!!)
        assertTrue(preferences.choices.value.showPlaybackInfo, "this device keeps it for the next video")
        assertEquals(PlaybackInfoState(visible = true), state.playbackInfo)
        assertEquals(true, state.options.single { it.id == PlayerOptionId.PLAYBACK_INFO }.on)
        assertEquals(listOf(true), engine.statsWanted)
        engineState { it.copy(positionSeconds = 101.0) }
        assertEquals(listOf(true), engine.statsWanted, "asked once, not on every state")

        dispatch(PlayerCommand.CloseMenu)
        dispatch(PlayerCommand.HideControls)
        assertEquals(PlaybackInfoState(visible = false), state.playbackInfo)
        assertEquals(listOf(true, false), engine.statsWanted)
        dispatch(PlayerCommand.ShowControls)
        assertEquals(listOf(true, false, true), engine.statsWanted)

        choices { it.copy(autoHidePlaybackInfo = false) }
        dispatch(PlayerCommand.HideControls)
        assertEquals(PlaybackInfoState(visible = true), state.playbackInfo, "without auto-hide it stays with the controls down")
        assertEquals(listOf(true, false, true), engine.statsWanted)

        store.onPictureInPictureChanged(true)
        assertNull(state.playbackInfo, "none in picture in picture")
        assertEquals(listOf(true, false, true, false), engine.statsWanted)
        store.onPictureInPictureChanged(false)

        press(InputKey.INFO)
        assertFalse(preferences.choices.value.showPlaybackInfo, "a remote's Info key turns it off")
        assertNull(state.playbackInfo)
        dispatch(PlayerCommand.ToggleInfo)
        assertTrue(preferences.choices.value.showPlaybackInfo)
        store.release()
        assertEquals(false, engine.statsWanted.last(), "a released player stops the reading")
    }

    @Test
    fun aPlaybackOpensWithTheInfoTheDeviceKept() = playerTest(preferences = PlayerChoices(showPlaybackInfo = true)) {
        playing()
        assertEquals(PlaybackInfoState(visible = true), state.playbackInfo)
        assertEquals(listOf(true), engine.statsWanted)
    }

    @Test
    fun liveValuesUpdateInTheirRowsAboutTwiceASecond() = playerTest(preferences = PlayerChoices(showPlaybackInfo = true)) {
        playing()
        engineState {
            it.copy(
                tracks = listOf(Track(1, TrackKind.VIDEO, null, null, "hevc", selected = true, external = false)),
                video = VideoInfo(3840, 2160, "hevc", 23.976, DynamicRange.HDR10),
                hwdec = "videotoolbox",
                cacheEndSeconds = 110.0,
            )
        }
        fun read(): List<InfoSection> {
            advance(PlaybackInfoReader.POLL_INTERVAL_MS.milliseconds)
            return store.playbackInfo.sections.value
        }
        // The engine's first reading: the bitrate isn't known yet.
        engineState { it.copy(stats = PlaybackStats(droppedFrames = 0, decoderDroppedFrames = 0, delayedFrames = 0, cacheBytes = 1_048_576)) }
        val first = read()
        assertEquals("—", first.row(InfoSectionId.VIDEO, "Bitrate"))
        assertEquals("10 s · 1.0 MB", first.row(InfoSectionId.BUFFER, "Cache"))
        engineState {
            it.copy(
                cacheEndSeconds = 111.0,
                stats = it.stats!!.copy(videoBitrate = 38_600_000.0, droppedFrames = 2, cacheBytes = 2_097_152, downloadBytesPerSecond = 1_048_576),
            )
        }
        val second = read()
        assertEquals("38.6 Mb/s", second.row(InfoSectionId.VIDEO, "Bitrate"))
        assertEquals("2 (decoder 0)", second.row(InfoSectionId.PERFORMANCE, "Dropped frames"))
        assertEquals("11 s · 2.0 MB", second.row(InfoSectionId.BUFFER, "Cache"))
        assertEquals("1.0 MB/s", second.row(InfoSectionId.BUFFER, "Download speed"))
        assertEquals(first.map { s -> s.id to s.rows.map { it.label } }, second.map { s -> s.id to s.rows.map { it.label } }, "live values change no row")
        // Another file: the last one's stats go until the engine reads the new one's.
        engineState { it.copy(stats = null) }
        assertEquals(null, read().rowOrNull(InfoSectionId.VIDEO, "Bitrate"))
    }

    @Test
    fun liveAndDownloadedPlaybackHaveNoPlayMethod() = playerTest(preferences = PlayerChoices(showPlaybackInfo = true)) {
        playing()
        fun playMethod(): String? {
            advance(PlaybackInfoReader.POLL_INTERVAL_MS.milliseconds)
            return store.playbackInfo.sections.value.rowOrNull(InfoSectionId.APP, "Play method")
        }
        sessionInfo { it.copy(transcoding = true) }
        assertEquals("Transcoding", playMethod())
        sessionInfo { it.copy(local = true) }
        assertNull(playMethod())
        sessionInfo { it.copy(local = false, live = true) }
        assertNull(playMethod())
    }

    private fun List<InfoSection>.rowOrNull(id: InfoSectionId, label: String): String? =
        firstOrNull { it.id == id }?.rows?.firstOrNull { it.label == label }?.value

    private fun List<InfoSection>.row(id: InfoSectionId, label: String): String =
        rowOrNull(id, label) ?: error("no $label row in $id: $this")
}
