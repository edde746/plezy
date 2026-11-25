package com.edde746.plezy.playback.mpv

import com.edde746.plezy.playback.AudioDevice
import com.edde746.plezy.playback.AudioInfo
import com.edde746.plezy.playback.Chapter
import com.edde746.plezy.playback.DynamicRange
import com.edde746.plezy.playback.EngineErrorKind
import com.edde746.plezy.playback.PlaybackStats
import com.edde746.plezy.playback.SubtitleFrame
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import com.edde746.plezy.playback.VideoInfo
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class MpvStateTest {
    @Test
    fun tracksCarryContainerFlagsAndAudioChannels() {
        assertEquals(
            listOf(
                Track(1, TrackKind.VIDEO, null, null, "hevc", selected = true, external = false, isDefault = true, codecProfile = "Main 10"),
                Track(
                    1, TrackKind.AUDIO, "TrueHD 7.1", "eng", "truehd", selected = true, external = false, isDefault = true,
                    channels = 8, codecProfile = "Dolby TrueHD + Dolby Atmos",
                ),
                Track(2, TrackKind.AUDIO, null, "fre", "aac", selected = false, external = false, visualImpaired = true, channels = 2),
                Track(1, TrackKind.SUBTITLE, "SDH", "eng", "hdmv_pgs_subtitle", selected = false, external = false, hearingImpaired = true),
                Track(2, TrackKind.SUBTITLE, "Forced", "eng", "ass", selected = true, external = true, isDefault = true, forced = true),
            ),
            MpvState.tracks(TRACK_LIST),
        )
    }

    @Test
    fun tracksWithoutAnIdOrOfUnknownTypeAreSkipped() {
        assertEquals(emptyList(), MpvState.tracks("""[{"type":"sub","codec":"subrip"},{"id":9,"type":"attachment"},"junk",null]"""))
        assertEquals(emptyList(), MpvState.tracks(null))
    }

    @Test
    fun aChannelCountIsKeptForAudioOnlyAndWhenPositive() {
        val tracks = MpvState.tracks(
            """
            [{"id":1,"type":"video","demux-channel-count":2},{"id":1,"type":"audio"},
             {"id":2,"type":"audio","demux-channel-count":0},{"id":3,"type":"audio","demux-channel-count":6}]
            """,
        )
        assertEquals(listOf(null, null, null, 6), tracks.map { it.channels })
    }

    @Test
    fun blankTrackStringsAreNone() {
        val track = MpvState.tracks("""[{"id":1,"type":"audio","title":"","lang":" ","codec":"","codec-profile":""}]""").single()
        assertEquals(listOf(null, null, null, null), listOf(track.title, track.language, track.codec, track.codecProfile))
    }

    @Test
    fun theSecondSubtitlesTrackIsSecondaryNotSelected() {
        val tracks = MpvState.tracks(
            """[{"id":1,"type":"sub","selected":true,"main-selection":0},{"id":2,"type":"sub","selected":true,"main-selection":1},
               {"id":3,"type":"sub","selected":false}]""",
        )
        assertEquals(listOf(true to false, false to true, false to false), tracks.map { it.selected to it.secondary })
    }

    @Test
    fun videoTracksCarryTheDolbyVisionRecordAndTheContainersRateAndSizeSelectedOrNot() {
        assertEquals(listOf(MpvState.VideoTrack(1, true, "hevc", "Main 10", 8, 6, 23.976024, 3840, 2160)), MpvState.videoTracks(TRACK_LIST))
        // At the file's preload nothing is selected yet.
        val preloaded = """[{"id":1,"type":"video","selected":false,"codec":"hevc","dolby-vision-profile":5,"dolby-vision-level":6}]"""
        assertEquals(listOf(MpvState.VideoTrack(1, false, "hevc", null, 5, 6)), MpvState.videoTracks(preloaded))
    }

    @Test
    fun videoInfoTakesSizeFromParamsAndCodecAndFpsFromTheSelectedTrack() {
        val tracks =
            """
            [{"id":1,"type":"video","codec":"hevc","selected":false,"demux-fps":24.0},
             {"id":2,"type":"video","codec":"av1","selected":true,"demux-fps":23.976}]
            """
        assertEquals(
            VideoInfo(3840, 2160, "av1", 23.976, DynamicRange.SDR).tagged("bt.1886"),
            MpvState.videoInfo(params(gamma = "bt.1886"), tracks),
        )
    }

    @Test
    fun videoInfoCarriesThePeakAndTheColourTagsOfTheParams() {
        val video = MpvState.videoInfo(params(gamma = "pq"), PLAIN_HEVC)!!
        assertEquals(listOf(10.0, "pq", "bt.2020", "bt.2020-ncl"), listOf(video.sigPeak, video.gamma, video.primaries, video.colorMatrix))
        val bare = MpvState.videoInfo("""{"pixelformat":"yuv420p","w":1920,"h":1080}""", PLAIN_HEVC)!!
        assertEquals(listOf(null, null, null, null), listOf(bare.sigPeak, bare.gamma, bare.primaries, bare.colorMatrix))
    }

    @Test
    fun theTransferDecidesWithoutDolbyVision() {
        assertEquals(DynamicRange.HDR10, MpvState.videoInfo(params(gamma = "pq"), PLAIN_HEVC)?.dynamicRange)
        assertEquals(DynamicRange.HLG, MpvState.videoInfo(params(gamma = "hlg"), PLAIN_HEVC)?.dynamicRange)
        assertEquals(DynamicRange.SDR, MpvState.videoInfo(params(gamma = "bt.1886"), PLAIN_HEVC)?.dynamicRange)
        assertEquals(DynamicRange.SDR, MpvState.videoInfo(params(gamma = "srgb"), PLAIN_HEVC)?.dynamicRange)
        assertNull(MpvState.videoInfo(params(gamma = "pq"), PLAIN_HEVC)?.doviProfile)
        assertNull(MpvState.videoInfo(params(gamma = "pq"), PLAIN_HEVC)?.fps, "no demux-fps, no fps")
    }

    @Test
    fun dolbyVisionWinsOverTheBaseLayerTransfer() {
        // Profile 8.1: an HDR10 (PQ) base layer plus the RPU.
        assertEquals(
            VideoInfo(3840, 2160, "hevc", 23.976024, DynamicRange.DOLBY_VISION, doviProfile = 8).tagged("pq"),
            MpvState.videoInfo(params(gamma = "pq"), TRACK_LIST),
        )
        // Profile 8.4: an HLG base layer.
        assertEquals(DynamicRange.DOLBY_VISION, MpvState.videoInfo(params(gamma = "hlg"), TRACK_LIST)?.dynamicRange)
        // Profile 5: IPTPQc2 frames, known from the colour system even without a configuration record on the track.
        val p5 = MpvState.videoInfo(params(gamma = "pq", colormatrix = "dolbyvision"), PLAIN_HEVC)
        assertEquals(DynamicRange.DOLBY_VISION to null, p5?.dynamicRange to p5?.doviProfile)
    }

    @Test
    fun theDolbyVisionRecordComesFromTheSelectedVideoTrackOnly() {
        val tracks = """[{"id":1,"type":"video","selected":false,"dolby-vision-profile":5},{"id":2,"type":"video","selected":true}]"""
        assertEquals(DynamicRange.HDR10, MpvState.videoInfo(params(gamma = "pq"), tracks)?.dynamicRange)
    }

    @Test
    fun theRotationIsTheTurnMpvShowsThePictureWith() {
        // A phone's upright video stored sideways: 1920x1080 frames shown turned a quarter clockwise.
        val turned = MpvState.videoInfo("""{"pixelformat":"mediacodec","w":1920,"h":1080,"rotate":90,"gamma":"bt.1886"}""", PLAIN_HEVC)!!
        assertEquals(90, turned.rotation)
        assertEquals(0, MpvState.videoInfo("""{"pixelformat":"yuv420p","w":1920,"h":1080}""", PLAIN_HEVC)?.rotation, "no rotate, no turn")
    }

    @Test
    fun noVideoInfoBeforeTheOutputHasASizeAndAFormat() {
        assertNull(MpvState.videoInfo(null, TRACK_LIST))
        assertNull(MpvState.videoInfo("""{"pixelformat":"mediacodec","w":0,"h":0,"gamma":"pq"}""", TRACK_LIST))
        // Before the first frame mpv knows the container's size only: no transfer yet, so an HDR file would read as SDR.
        assertNull(MpvState.videoInfo("""{"w":3840,"h":2160}""", TRACK_LIST))
        // Before a track list arrives the codec and frame rate are unknown, not wrong.
        assertEquals(VideoInfo(3840, 2160, null, null, DynamicRange.HDR10).tagged("pq"), MpvState.videoInfo(params(gamma = "pq"), null))
    }

    @Test
    fun audioInfoIsTheDecoderOutputAndTheSelectedTracksCodec() {
        val params = """{"format":"s32","samplerate":48000,"channels":"7.1","hr-channels":"7.1","channel-count":8}"""
        assertEquals(AudioInfo(codec = "truehd", channels = 8, sampleRate = 48000), MpvState.audioInfo(params, TRACK_LIST))
        assertNull(MpvState.audioInfo("{}", TRACK_LIST))
        assertNull(MpvState.audioInfo(null, TRACK_LIST))
    }

    @Test
    fun passthroughIsABitstreamOutputFormat() {
        for (format in listOf("spdif-ac3", "spdif-eac3", "spdif-dts", "spdif-dtshd", "spdif-truehd")) {
            assertTrue(MpvState.audioPassthrough(format), format)
        }
        // The outputs' PCM formats, and no output.
        for (format in listOf("s16", "float", "s32", "floatp")) {
            assertFalse(MpvState.audioPassthrough(format), format)
        }
        assertFalse(MpvState.audioPassthrough(null))
    }

    @Test
    fun thePassthroughFormatIsTheBitstreamWithoutItsWrapping() {
        assertEquals("truehd", MpvState.passthroughFormat("spdif-truehd"))
        assertEquals("dtshd", MpvState.passthroughFormat("spdif-dtshd"))
        assertNull(MpvState.passthroughFormat("float"), "decoded PCM")
        assertNull(MpvState.passthroughFormat(null))
    }

    @Test
    fun aStatsReadingMapsMpvsProperties() {
        // An HDR10 remux decoded on d3d11va, its TrueHD in passthrough, 42 s cached.
        val strings = mapOf(
            "filename" to "remux.mkv",
            "file-format" to "mkv",
            "video-params" to
                """
                {"pixelformat":"d3d11","hw-pixelformat":"p010","w":3840,"h":2160,"dw":3840,"dh":2160,"aspect":1.777778,
                 "par":1.000000,"colormatrix":"bt.2020-ncl","colorlevels":"limited","primaries":"bt.2020","gamma":"pq",
                 "sig-peak":4.926108,"light":"display","chroma-location":"left","rotate":0,"min-luma":0.000100,
                 "max-luma":1000.000000,"max-cll":1000.000000,"max-fall":41.000000}
                """,
            "audio-params/hr-channels" to "5.1(side)",
            "current-ao" to "wasapi",
            "audio-out-params/format" to "spdif-truehd",
            "demuxer-cache-state" to
                """
                {"cache-end":52.3,"reader-pts":10.1,"cache-duration":42.2,"eof":false,"underrun":false,"idle":true,
                 "total-bytes":20123456,"fw-bytes":18000000,"raw-input-rate":12300000,"debug-low-level-seeks":0,
                 "debug-byte-level-seeks":0,"debug-ts-last":52.3,
                 "ts-per-stream":[{"type":"video","cache-duration":42.2,"reader-pts":10.1,"cache-end":52.3}],
                 "bof-cached":true,"eof-cached":false,"seekable-ranges":[{"start":0.0,"end":52.3}]}
                """,
        )
        val numbers = mapOf(
            "file-size" to 14_600_000.0,
            "video-bitrate" to 3_912_448.0,
            "audio-bitrate" to 1_024_000.0,
            "frame-drop-count" to 2.0,
            "decoder-frame-drop-count" to 0.0,
            "vo-delayed-frame-count" to 1.0,
            "cache-speed" to 12_300_000.0,
            "cache-buffering-state" to 100.0,
        )
        val stats = MpvState.stats(
            text = { assertTrue(it in MpvState.STATS_TEXT_PROPERTIES, it); strings[it] },
            number = { assertTrue(it in MpvState.STATS_NUMBER_PROPERTIES, it); numbers[it] },
            display = MpvState.DisplayMode(3840, 2160, 59.94),
        )
        val expected = PlaybackStats(
            fileName = "remux.mkv",
            fileFormat = "mkv",
            fileSizeBytes = 14_600_000,
            pixelFormat = "d3d11",
            hwPixelFormat = "p010",
            primaries = "bt.2020",
            transfer = "pq",
            colorMatrix = "bt.2020-ncl",
            maxCll = 1000.0,
            maxFall = 41.0,
            masteringMinLuminance = 0.0001,
            masteringMaxLuminance = 1000.0,
            videoBitrate = 3_912_448.0,
            audioBitrate = 1_024_000.0,
            droppedFrames = 2,
            decoderDroppedFrames = 0,
            delayedFrames = 1,
            displayWidth = 3840,
            displayHeight = 2160,
            displayRefreshRate = 59.94,
            channelLayout = "5.1(side)",
            audioOutput = "wasapi",
            passthroughFormat = "truehd",
            cacheBytes = 18_000_000,
            downloadBytesPerSecond = 12_300_000,
            bufferingPercent = 100,
        )
        assertEquals(expected, stats)
    }

    @Test
    fun aStatsReadingBeforeAnythingIsKnownIsEmpty() {
        assertEquals(PlaybackStats(), MpvState.stats({ null }, { null }, display = null))
    }

    @Test
    fun aStatsReadingTakesBlankTextAndNegativeNumbersAsNone() {
        val strings = mapOf(
            "filename" to "",
            "file-format" to " ",
            "video-params" to """{"pixelformat":"","w":3840,"h":2160}""",
            "audio-params/hr-channels" to "",
            "current-ao" to "",
            "demuxer-cache-state" to """{"fw-bytes":-1}""",
        )
        val numbers = mapOf(
            "file-size" to -1.0,
            "video-bitrate" to Double.NaN,
            "audio-bitrate" to -1.0,
            "frame-drop-count" to -1.0,
            "cache-speed" to -1.0,
            "cache-buffering-state" to -1.0,
        )
        assertEquals(PlaybackStats(), MpvState.stats({ strings[it] }, { numbers[it] }, display = null))
    }

    @Test
    fun softwareFramesCarryTheirOwnFormat() {
        val strings = mapOf(
            "video-params" to
                """
                {"pixelformat":"yuv420p10","average-bpp":15,"w":3840,"h":2160,"dw":3840,"dh":2160,
                 "colormatrix":"bt.2020-ncl","colorlevels":"limited","primaries":"bt.2020","gamma":"pq",
                 "sig-peak":4.926108,"light":"display","chroma-location":"left","rotate":0}
                """,
        )
        val stats = MpvState.stats({ strings[it] }, { null }, display = null)
        assertEquals("yuv420p10", stats.pixelFormat)
        assertNull(stats.hwPixelFormat, "software frames have no hardware format")
        assertNull(stats.maxCll, "no HDR10 metadata, no light levels")
    }

    @Test
    fun theOutputRangeIsTheTransferMpvRendersTo() {
        assertEquals(DynamicRange.HDR10, MpvState.outputRange(target("pq")))
        assertEquals(DynamicRange.HLG, MpvState.outputRange(target("hlg")))
        assertEquals(DynamicRange.SDR, MpvState.outputRange(target("bt.1886")), "an HDR video tone-mapped for an SDR target")
        assertEquals(DynamicRange.SDR, MpvState.outputRange(target("srgb")))
        assertNull(MpvState.outputRange(target("auto")))
        assertNull(MpvState.outputRange(null), "no target before the output is configured")
    }

    @Test
    fun androidsGlVoOutputIsItsRenderTarget() {
        assertEquals(DynamicRange.HDR10, gl(params(gamma = "pq"), target("pq")))
        assertEquals(DynamicRange.SDR, gl(params(gamma = "pq"), target("bt.1886")), "the GL vo tone-maps PQ to its SDR target")
        assertNull(gl(params(gamma = "pq"), target("auto")))
        assertNull(gl(params(gamma = "pq"), null), "no target yet")
    }

    @Test
    fun androidsPlaneOutputIsTheFramesHdrFormatWhereTheDisplayTakesIt() {
        val pq = params(gamma = "pq")
        val hlg = params(gamma = "hlg")
        val hdrDisplay = setOf(DynamicRange.HDR10, DynamicRange.HLG)
        assertEquals(DynamicRange.HDR10, plane(pq, hdrDisplay))
        assertEquals(DynamicRange.HLG, plane(hlg, hdrDisplay))
        assertEquals(DynamicRange.SDR, plane(pq, emptySet()), "an SDR display: Android tone-maps")
        assertEquals(DynamicRange.SDR, plane(hlg, setOf(DynamicRange.HDR10)), "no HLG on the display")
        assertEquals(DynamicRange.SDR, plane(params(gamma = "bt.1886"), setOf(DynamicRange.HDR10)))
        assertNull(plane(null, setOf(DynamicRange.HDR10)), "no frames yet")
        assertEquals(DynamicRange.HDR10, plane(pq, setOf(DynamicRange.HDR10), target = target("bt.1886")), "the plane's output is not mpv's render target")
    }

    @Test
    fun dolbyVisionReachesThePlaneOnlyFromADolbyVisionDecoderOnADolbyVisionDisplay() {
        val pq = params(gamma = "pq")
        val dvDisplay = setOf(DynamicRange.DOLBY_VISION, DynamicRange.HDR10)
        assertEquals(DynamicRange.DOLBY_VISION, plane(pq, dvDisplay, dolbyVisionDecoder = true))
        // Profile 8 decoded as HEVC: its HDR10 base layer.
        assertEquals(DynamicRange.HDR10, plane(pq, dvDisplay, dolbyVisionDecoder = false))
        // A Dolby Vision decoder without a Dolby Vision display (profile 5 converted): the transfer it reports.
        assertEquals(DynamicRange.HDR10, plane(pq, setOf(DynamicRange.HDR10), dolbyVisionDecoder = true))
    }

    @Test
    fun theSdrHeadroomHintTakesTheDisplayToSdr() {
        assertEquals(DynamicRange.SDR, plane(params(gamma = "pq"), setOf(DynamicRange.HDR10), sdrHeadroom = true))
        assertEquals(DynamicRange.SDR, gl(null, target("pq"), sdrHeadroom = true))
        assertNull(plane(null, setOf(DynamicRange.HDR10), sdrHeadroom = true), "still unknown before the frames")
    }

    @Test
    fun chaptersWithoutATimeAreSkippedAndBlankTitlesAreNone() {
        val chapters = MpvState.chapters(
            """[{"title":"Opening","time":0.0},{"title":"","time":93.5},{"title":" ","time":120.0},{"title":"No time"},"junk"]""",
        )
        assertEquals(listOf(Chapter("Opening", 0.0), Chapter(null, 93.5), Chapter(null, 120.0)), chapters)
        assertEquals(emptyList(), MpvState.chapters(null))
    }

    @Test
    fun audioDevicesKeepMpvsOrderAndNeedAName() {
        val devices = MpvState.audioDevices(
            """
            [{"name":"auto","description":"Autoselect device"},
             {"name":"pipewire/alsa_output.pci-0000_00_1f.3.analog-stereo","description":"Built-in Audio Analog Stereo"},
             {"name":"pulse/hdmi"},{"description":"No name"},{"name":"","description":"Empty name"},"junk"]
            """,
        )
        assertEquals(
            listOf(
                AudioDevice("auto", "Autoselect device"),
                AudioDevice("pipewire/alsa_output.pci-0000_00_1f.3.analog-stereo", "Built-in Audio Analog Stereo"),
                AudioDevice("pulse/hdmi", "pulse/hdmi"),
            ),
            devices,
        )
        assertEquals(emptyList(), MpvState.audioDevices(null))
    }

    @Test
    fun theSubtitleFrameIsThePictureBetweenOsdDimensionsBands() {
        // An upright Pixel 7: a 16:9 picture across the middle of the 1080×2400 plane.
        val upright = """{"w":1080,"h":2400,"par":1.0,"aspect":0.45,"mt":896,"mb":897,"ml":0,"mr":0}"""
        assertEquals(SubtitleFrame(2400.0, 896.0, 897.0), MpvState.subtitleFrame(upright))
        assertEquals(SubtitleFrame.SCREEN, MpvState.subtitleFrame("""{"w":0,"h":0,"mt":0,"mb":0}"""), "no output yet")
        assertEquals(SubtitleFrame.SCREEN, MpvState.subtitleFrame(null))
    }

    @Test
    fun theSurfaceAspectIsTheOsdSize() {
        assertEquals(16.0 / 9.0, MpvState.surfaceAspect("""{"w":1920,"h":1080,"mt":0,"mb":0}"""))
        assertNull(MpvState.surfaceAspect("""{"w":0,"h":0}"""))
        assertNull(MpvState.surfaceAspect("""{"w":1920}"""))
        assertNull(MpvState.surfaceAspect(null))
    }

    @Test
    fun theOsdDimensionsAreTheOutputAndItsBands() {
        assertEquals(
            MpvState.OsdDimensions(width = 1920.0, height = 1080.0, left = 240.0, right = 240.0, top = 0.0, bottom = 0.0),
            MpvState.osdDimensions("""{"w":1920,"h":1080,"ml":240,"mr":240,"mt":0,"mb":0}"""),
        )
        assertEquals(
            MpvState.OsdDimensions(width = 1280.0, height = 720.0, left = 0.0, right = 0.0, top = 0.0, bottom = 0.0),
            MpvState.osdDimensions("""{"w":1280,"h":720}"""),
        )
        assertNull(MpvState.osdDimensions("""{"w":0,"h":0,"ml":0,"mr":0}"""))
        assertNull(MpvState.osdDimensions(null))
    }

    @Test
    fun theVideoCacheIsTheVideoStreamsEntryAndAbsentWithoutVideo() {
        val playing =
            """
            {"cache-end":52.3,"reader-pts":10.1,"cache-duration":4.2,"eof":false,"underrun":false,"idle":false,
             "fw-bytes":18000000,"ts-per-stream":[{"type":"video","cache-duration":42.2,"reader-pts":10.1,"cache-end":52.3},
             {"type":"audio","cache-duration":4.2,"reader-pts":48.1,"cache-end":52.3}],"bof-cached":false,
             "eof-cached":false,"seekable-ranges":[]}
            """
        assertEquals(MpvState.VideoCache(seconds = 42.2, readerPts = 10.1), MpvState.videoCache(playing))
        assertNull(MpvState.videoCache("""{"ts-per-stream":[{"type":"audio","cache-duration":12.0,"reader-pts":3.0}]}"""))
        assertNull(MpvState.videoCache(null), "no file")
    }

    @Test
    fun theCacheStartIsTheStartOfTheSeekableRangeHoldingThePosition() {
        // mpv 0.41 a minute into a live HLS (the Mac's measurement, 21 Oct), with a second range from an earlier seek.
        val live = """{"cache-end":63.9,"seekable-ranges":[{"start":0.0,"end":20.5},{"start":30.0,"end":62.1}]}"""
        assertEquals(30.0, MpvState.cacheStart(live, 60.1))
        assertEquals(0.0, MpvState.cacheStart(live, 12.0))
        assertNull(MpvState.cacheStart(live, 25.0), "between the ranges")
        assertNull(MpvState.cacheStart("""{"seekable-ranges":[]}""", 3.0), "nothing read yet")
        assertNull(MpvState.cacheStart(null, 3.0), "no file")
    }

    @Test
    fun theHttpStatusComesFromFfmpegsLogLine() {
        assertEquals(404, MpvState.httpStatus("http: HTTP error 404 Not Found"))
        assertEquals(403, MpvState.httpStatus("https: HTTP error 403 Forbidden"))
        assertNull(MpvState.httpStatus("Failed to open http://host/file.mkv."))
    }

    @Test
    fun mpvsErrorCodesSayWhatThePlayerTellsTheUser() {
        assertEquals(EngineErrorKind.OPEN, MpvState.errorKind(-13), "loading failed")
        assertEquals(listOf(EngineErrorKind.AUDIO_OUTPUT, EngineErrorKind.DECODE, EngineErrorKind.DECODE), listOf(-14, -15, -16).map(MpvState::errorKind), "no audio output, no video output, nothing to play")
        assertEquals(listOf(EngineErrorKind.FORMAT, EngineErrorKind.FORMAT), listOf(-17, -18).map(MpvState::errorKind), "unknown format, unsupported")
        assertEquals(EngineErrorKind.OTHER, MpvState.errorKind(-12), "a command mpv refused")
    }

    @Test
    fun unparsableOrMismatchedTextReadsAsAbsent() {
        assertEquals(emptyList(), MpvState.tracks("""[{"id":1"""))
        assertEquals(emptyList(), MpvState.tracks("{}"), "an object where a list belongs")
        assertNull(MpvState.videoInfo("[]", TRACK_LIST), "a list where an object belongs")
        assertEquals(emptyList(), MpvState.chapters("not json"))
        assertEquals(SubtitleFrame.SCREEN, MpvState.subtitleFrame(""))
    }

    @Test
    fun aLoadBuffersUntilItsFirstFrameShows() {
        assertTrue(buffering(firstFrameShown = false), "opening")
        assertFalse(buffering(), "playing")
        assertFalse(buffering(open = false, firstFrameShown = false), "no load went out")
    }

    @Test
    fun aPlayingFileBuffersWhileMpvWaitsForDataOrSeeks() {
        assertTrue(buffering(pausedForCache = true))
        assertTrue(buffering(seeking = true))
    }

    @Test
    fun aFailedOrEndedFileNeverBuffers() {
        assertFalse(buffering(failed = true, firstFrameShown = false), "failed to open")
        assertFalse(buffering(failed = true, pausedForCache = true))
        assertFalse(buffering(eof = true, pausedForCache = true, seeking = true))
        assertFalse(buffering(failed = true, held = true), "a display switch over a failed file")
        assertFalse(buffering(eof = true, held = true), "a display switch at the end")
    }

    @Test
    fun aPlayingFileBuffersWhileThePlatformHoldsIt() {
        assertTrue(buffering(held = true))
        assertFalse(buffering(open = false, held = true), "no load went out")
    }

    /** [MpvState.buffering] of a file that is playing, but for the given inputs. */
    private fun buffering(
        open: Boolean = true,
        failed: Boolean = false,
        eof: Boolean = false,
        firstFrameShown: Boolean = true,
        held: Boolean = false,
        pausedForCache: Boolean = false,
        seeking: Boolean = false,
    ) = MpvState.buffering(open, failed, eof, firstFrameShown, held, pausedForCache, seeking)

    @Test
    fun aMeasuredRateIsTheNearestStandardOneWithinTenFramesToTheMillisecond() {
        assertEquals(24000.0 / 1001, MpvState.standardRate(23.98))
        assertEquals(24000.0 / 1001, MpvState.standardRate(10 / 0.417), "ten 24 fps frames read as 417 ms")
        assertEquals(25.0, MpvState.standardRate(25.02))
        assertEquals(60000.0 / 1001, MpvState.standardRate(59.94))
        assertEquals(120.0, MpvState.standardRate(120.0))
        assertNull(MpvState.standardRate(24.417), "a misdetected rate switches nothing")
        assertNull(MpvState.standardRate(15.0))
        assertNull(MpvState.standardRate(null))
    }

    @Test
    fun withoutAContainerOrTrackRateTheVideoTakesTheStandardRateMpvMeasures() {
        val params = Json.parseToJsonElement("""{"pixelformat":"yuv420p","w":1920,"h":1080}""").jsonObject
        val tracks = Json.parseToJsonElement(PLAIN_HEVC).jsonArray
        assertEquals(24000.0 / 1001, MpvState.videoInfo(params, tracks, estimatedFps = 23.97)?.fps)
        assertNull(MpvState.videoInfo(params, tracks, estimatedFps = 24.417)?.fps)
        assertEquals(25.0, MpvState.videoInfo(params, tracks, containerFps = 25.0, estimatedFps = 23.97)?.fps, "the container's rate wins")
    }

    /** [this] with the peak and colour tags of [params] for [gamma]. */
    private fun VideoInfo.tagged(gamma: String) = copy(sigPeak = 10.0, gamma = gamma, primaries = "bt.2020", colorMatrix = "bt.2020-ncl")

    /** `video-params` of 4K HEVC 10-bit frames in BT.2020 with the transfer [gamma]. */
    private fun params(gamma: String, colormatrix: String = "bt.2020-ncl") =
        """
        {"pixelformat":"yuv420p10","w":3840,"h":2160,"dw":3840,"dh":2160,"aspect":1.777778,"par":1.0,
         "colormatrix":"$colormatrix","colorlevels":"limited","primaries":"bt.2020","gamma":"$gamma","sig-peak":10.0,
         "light":"display","chroma-location":"left","rotate":0}
        """

    /** `video-target-params` of a GL vo rendering to the transfer [gamma]. */
    private fun target(gamma: String) = """{"pixelformat":"rgba","w":3840,"h":2160,"primaries":"bt.2020","gamma":"$gamma"}"""

    /** [MpvState.androidOutputRange] on the video plane. */
    private fun plane(
        videoParams: String?,
        displayHdr: Set<DynamicRange>,
        dolbyVisionDecoder: Boolean = false,
        sdrHeadroom: Boolean = false,
        target: String? = null,
    ) = MpvState.androidOutputRange(MpvState.transfer(videoParams), target, videoPlane = true, displayHdr, dolbyVisionDecoder, sdrHeadroom)

    /** [MpvState.androidOutputRange] on a GL vo, the display taking no HDR. */
    private fun gl(videoParams: String?, target: String?, sdrHeadroom: Boolean = false) =
        MpvState.androidOutputRange(MpvState.transfer(videoParams), target, videoPlane = false, emptySet(), dolbyVisionDecoder = false, sdrHeadroom)

    private companion object {
        /** Shaped like mpv 0.41's `track-list` for a DV P8.1 file with a 7.1 track and a stereo audio description. */
        const val TRACK_LIST =
            """
            [
              {"id":1,"type":"video","src-id":0,"image":false,"albumart":false,"default":true,"forced":false,
               "dependent":false,"visual-impaired":false,"hearing-impaired":false,"external":false,"selected":true,
               "main-selection":0,"ff-index":0,"decoder":"hevc","codec":"hevc","codec-profile":"Main 10","demux-w":3840,
               "demux-h":2160,"demux-fps":23.976024,"dolby-vision-profile":8,"dolby-vision-level":6},
              {"id":1,"type":"audio","src-id":1,"lang":"eng","title":"TrueHD 7.1","audio-channels":8,"default":true,
               "forced":false,"hearing-impaired":false,"external":false,"selected":true,"codec":"truehd",
               "codec-profile":"Dolby TrueHD + Dolby Atmos","demux-channel-count":8,"demux-channels":"7.1",
               "demux-samplerate":48000},
              {"id":2,"type":"audio","src-id":2,"lang":"fre","default":false,"forced":false,"visual-impaired":true,
               "external":false,"selected":false,"codec":"aac","demux-channel-count":2},
              {"id":1,"type":"sub","src-id":3,"lang":"eng","title":"SDH","default":false,"forced":false,
               "hearing-impaired":true,"external":false,"selected":false,"codec":"hdmv_pgs_subtitle"},
              {"id":2,"type":"sub","src-id":4,"lang":"eng","title":"Forced","default":true,"forced":true,
               "external":true,"selected":true,"codec":"ass"}
            ]
            """

        /** A selected HEVC track without a Dolby Vision record or a frame rate. */
        const val PLAIN_HEVC = """[{"id":1,"type":"video","selected":true,"codec":"hevc"}]"""
    }
}
