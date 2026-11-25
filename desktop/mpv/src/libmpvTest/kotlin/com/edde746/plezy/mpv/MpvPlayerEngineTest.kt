package com.edde746.plezy.mpv

import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import com.edde746.plezy.data.settings.DeviceSettings
import com.edde746.plezy.mpv.core.MpvCore
import com.edde746.plezy.mpv.video.VideoHost
import com.edde746.plezy.playback.AudioChannels
import com.edde746.plezy.playback.Downmix
import com.edde746.plezy.playback.EngineError
import com.edde746.plezy.playback.EngineState
import com.edde746.plezy.playback.HardwareDecoder
import com.edde746.plezy.playback.LOUDNESS_NORMALIZATION_FILTER
import com.edde746.plezy.playback.LoadRequest
import com.edde746.plezy.playback.PlaybackOptions
import com.edde746.plezy.playback.PlayerEngineListener
import com.edde746.plezy.playback.TrackKind
import com.sun.net.httpserver.HttpServer
import java.net.InetSocketAddress
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.test.fail
import kotlin.time.Duration.Companion.seconds

/**
 * The desktop engine on this machine's libmpv, without a window (`vo=null`) and, but for the passthrough playback on
 * this machine's own output, without audio output (`ao=null`).
 */
class MpvPlayerEngineTest {
    private val server = HttpServer.create(InetSocketAddress("127.0.0.1", 0), 0)
    private val engine = MpvPlayerEngine(WINDOWLESS, WindowlessHost())

    @AfterTest
    fun stop() {
        engine.release()
        engine.awaitReleased(10.seconds)
        server.stop(0)
    }

    /**
     * A file the server refuses fails with its status from the first error the engine publishes, even when the
     * engine's thread is busy as the refusal comes in (here a listener callback on the stats read the test asks for).
     * mpv buffers the log line naming the status ("HTTP error 404 Not Found") apart from its events and hands out the
     * end-file it explains first. The playback session decides on the first error whether a link expired.
     */
    @Test
    fun aRefusedFileFailsWithItsStatusWhileTheEngineIsBusy() {
        val asked = CountDownLatch(1)
        val answer = CountDownLatch(1)
        server.createContext("/") { exchange ->
            asked.countDown()
            answer.await(10, TimeUnit.SECONDS)
            exchange.sendResponseHeaders(404, -1)
            exchange.close()
        }
        server.start()
        val firstError = AtomicReference<EngineError?>()
        val failed = CountDownLatch(1)
        engine.setListener(object : PlayerEngineListener {
            override fun onState(state: EngineState) {
                if (state.stats != null && answer.count > 0) {
                    // The server answers while this callback holds the engine's thread.
                    answer.countDown()
                    Thread.sleep(1_000)
                }
                state.error?.let { if (firstError.compareAndSet(null, it)) failed.countDown() }
            }
        })
        engine.startWithoutWindow()
        val url = "http://127.0.0.1:${server.address.port}/missing.mkv"
        engine.load(LoadRequest(url = url, options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
        assertTrue(asked.await(10, TimeUnit.SECONDS), "mpv never asked for the file")
        engine.setStatsWanted(true)
        assertTrue(failed.await(10, TimeUnit.SECONDS), "no error; last state ${engine.currentState}")
        assertEquals(404, firstError.get()?.httpStatus, "the first error: ${firstError.get()}")
    }

    /**
     * A load starts the file's own values over (its tracks, position and length) and keeps what mpv's decoder and
     * outputs reported, here the audio, until mpv reports the next file's: mpv sends a property only when it differs
     * from what it sent last, so a next episode's identical value wouldn't come again.
     */
    @Test
    fun aLoadStartsTheFilesOwnValuesOverAndKeepsWhatTheDecoderReported() {
        val file = silentAc3()
        try {
            val reports = CopyOnWriteArrayList<EngineState>()
            val playing = CountDownLatch(1)
            val failed = CountDownLatch(1)
            engine.setListener(object : PlayerEngineListener {
                override fun onState(state: EngineState) {
                    reports += state
                    if (state.loaded && state.audio != null && state.tracks.isNotEmpty()) playing.countDown()
                    if (state.error != null) failed.countDown()
                }
            })
            engine.startWithoutWindow()
            engine.load(LoadRequest(url = file.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            assertTrue(playing.await(20, TimeUnit.SECONDS), "never played: ${engine.currentState}")
            val before = reports.size
            engine.load(LoadRequest(url = "$file.missing", options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            assertTrue(failed.await(20, TimeUnit.SECONDS), "no error; last state ${engine.currentState}")
            val first = reports.drop(before).first { !it.loaded }
            assertEquals(emptyList(), first.tracks, "the load's first report: $first")
            assertNotNull(first.audio, "the load's first report: $first")
        } finally {
            Files.deleteIfExists(file)
        }
    }

    /**
     * The display matching's hold while the display switches mode reports buffering only for a file that plays: never
     * over a failure, which the player shows (and a watch-together room must not wait for).
     */
    @Test
    fun aDisplayHoldOverAFailedFileIsNoBuffering() {
        val failed = CountDownLatch(1)
        engine.setListener(object : PlayerEngineListener {
            override fun onState(state: EngineState) {
                if (state.error != null) failed.countDown()
            }
        })
        engine.startWithoutWindow()
        val missing = Files.createTempDirectory("missing").resolve("missing.mkv")
        engine.load(LoadRequest(url = missing.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
        assertTrue(failed.await(20, TimeUnit.SECONDS), "no error; last state ${engine.currentState}")
        engine.holdForDisplay(true)
        // The mpv thread runs calls in order: once this read returns, the hold has run.
        engine.properties(emptyList())
        val s = engine.currentState
        assertNotNull(s.error, "the failure stays: $s")
        assertFalse(s.buffering, "held over a failure: $s")
    }

    /**
     * A file value mpv refuses (here a negative demuxer cache, as a broken setting would give) refuses the load: it
     * fails with mpv's reason, nothing opens, and the file playing is current again, with its id, frame and tracks.
     */
    @Test
    fun aFileValueMpvRefusesFailsTheLoadAndKeepsTheFilePlaying() {
        val file = silentAc3()
        try {
            val reports = CopyOnWriteArrayList<EngineState>()
            val playing = CountDownLatch(1)
            val failed = CountDownLatch(1)
            engine.setListener(object : PlayerEngineListener {
                override fun onState(state: EngineState) {
                    reports += state
                    if (state.loaded && state.tracks.isNotEmpty()) playing.countDown()
                    if (state.error != null) failed.countDown()
                }
            })
            engine.startWithoutWindow()
            val options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)
            val first = engine.load(LoadRequest(url = file.toString(), options = options))
            assertTrue(playing.await(20, TimeUnit.SECONDS), "never played: ${engine.currentState}")
            val tracks = engine.currentState.tracks
            val second = engine.load(LoadRequest(url = "$file.next", options = options.copy(demuxerMaxBytes = -1)))
            assertTrue(failed.await(20, TimeUnit.SECONDS), "no error; last state ${engine.currentState}")
            // The mpv thread runs calls in order: once this read returns, anything the load set off has run.
            engine.properties(emptyList())
            val failure = reports.first { it.error != null }
            assertEquals(second, failure.loadId, "the refused load's failure: $failure")
            val s = engine.currentState
            assertEquals(first, s.loadId, "the state after the refusal: $s")
            assertTrue(s.loaded, "the playing file's frame: $s")
            assertEquals(tracks, s.tracks, "the playing file's tracks: $s")
            assertEquals(null, s.error)
        } finally {
            Files.deleteIfExists(file)
        }
    }

    /**
     * The Passthrough setting in mpv's options: on, `audio-spdif` names every
     * format mpv wraps for a receiver and `audio-exclusive` is yes, from the core's start when set before it. Both go
     * back to mpv's defaults while the audio must be decoded (normalized, mixed down to stereo, played at another speed
     * than 1) and return after; a 5.1 mix only shapes decoded audio and leaves them. Off, mpv's defaults.
     */
    @Test
    fun passthroughSetsMpvsOptionsAndStepsAsideWhileTheAudioMustBeDecoded() {
        val on = mapOf("audio-spdif" to "ac3,eac3,dts,dts-hd,truehd", "audio-exclusive" to "yes")
        val off = mapOf("audio-spdif" to "", "audio-exclusive" to "no")
        fun options() = engine.properties(listOf("audio-spdif", "audio-exclusive"))
        engine.setAudioPassthrough(true)
        engine.startWithoutWindow()
        assertEquals(on, options(), "set before the core")
        engine.setAudioNormalization(true)
        assertEquals(off, options(), "normalized")
        engine.setAudioNormalization(false)
        assertEquals(on, options(), "normalized no more")
        engine.setAudioChannels(AudioChannels.STEREO)
        assertEquals(off, options(), "mixed down to stereo")
        engine.setAudioChannels(AudioChannels.SURROUND_51)
        assertEquals(on, options(), "mixed down to 5.1")
        engine.setSpeed(1.5)
        assertEquals(off, options(), "at 1.5×")
        engine.setSpeed(1.0)
        assertEquals(on, options(), "at 1×")
        engine.setAudioPassthrough(false)
        assertEquals(off, options(), "the setting off")
        engine.setAudioNormalization(true)
        engine.setAudioPassthrough(true)
        assertEquals(off, options(), "turned on while normalized")
        engine.setAudioNormalization(false)
        assertEquals(on, options(), "then normalized no more")
    }

    /**
     * The channel limit's fold and the loudness filter in mpv's properties: the stereo limit sets swresample's center
     * mix level for the center boost and the fold's normalization, the 5.1 limit no center boost, the original resets
     * both; normalization is the loudnorm chain in `af`, off an empty `af`.
     */
    @Test
    fun theChannelLimitFoldAndTheLoudnessFilterLandInMpvsProperties() {
        val names = listOf("audio-channels", "audio-swresample-o", "audio-normalize-downmix", "af")
        engine.startWithoutWindow()
        engine.setAudioChannels(AudioChannels.STEREO, Downmix(centerBoostDb = 9, normalize = true))
        engine.setAudioNormalization(true)
        val stereo = engine.properties(names)
        println("stereo limit, normalized: $stereo")
        assertEquals("stereo", stereo["audio-channels"])
        assertEquals("center_mix_level=1.9953", stereo["audio-swresample-o"])
        assertEquals("yes", stereo["audio-normalize-downmix"])
        assertEquals(LOUDNESS_NORMALIZATION_FILTER, stereo["af"])
        engine.setAudioChannels(AudioChannels.SURROUND_51, Downmix(centerBoostDb = 9, normalize = false))
        engine.setAudioNormalization(false)
        val surround = engine.properties(names)
        println("5.1 limit: $surround")
        assertEquals(mapOf("audio-channels" to "stereo,5.1", "audio-swresample-o" to "", "audio-normalize-downmix" to "no", "af" to ""), surround)
        engine.setAudioChannels(AudioChannels.ORIGINAL, Downmix())
        assertEquals("auto-safe", engine.properties(names)["audio-channels"])
    }

    /**
     * With the setting on, a Dolby Digital track plays on this machine's own audio output, whatever that takes: mpv
     * opens the output with the bitstream where it takes one, and decodes where it refuses it (no receiver), so the
     * playback goes on either way. The track is silent, the decoded audio muted; the output and its format are printed.
     */
    @Test
    fun aDolbyTrackPlaysOnThisMachinesOutputWithPassthroughOn() {
        val file = silentAc3()
        val output = MpvPlayerEngine(MpvEngineOptions(extraOptions = mapOf("vo" to "null", "mute" to "yes")), WindowlessHost())
        try {
            val error = AtomicReference<EngineError?>()
            val played = CountDownLatch(1)
            output.setListener(object : PlayerEngineListener {
                override fun onState(state: EngineState) {
                    state.error?.let(error::set)
                    if (state.error != null || state.positionSeconds >= 2.5) played.countDown()
                }
            })
            output.setAudioPassthrough(true)
            output.startWithoutWindow()
            output.load(LoadRequest(url = file.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            val reached = played.await(20, TimeUnit.SECONDS)
            val audio = output.properties(listOf("current-ao", "audio-out-params/format", "audio-spdif", "audio-exclusive"))
            println("passthrough on this machine's output: $audio, position ${output.currentState.positionSeconds} s")
            assertTrue(reached && error.get() == null, "no 2.5 s played within 20 s: error ${error.get()}, $audio, state ${output.currentState}")
            assertNotNull(audio["audio-out-params/format"], "the audio output never opened: $audio")
        } finally {
            output.release()
            output.awaitReleased(10.seconds)
            Files.deleteIfExists(file)
        }
    }

    /**
     * An HLS stream's subtitle line shows once after a seek back to before it, which reads the line again. mpv tells a
     * text line it decoded before by its byte position, which an HLS demuxer's packets don't carry, so each pass over
     * the line added a copy.
     */
    @Test
    fun anHlsSubtitleLineShowsOnceAfterASeekBackOverIt() {
        val dir = Files.createTempDirectory("hls")
        val audio = silentAc3()
        try {
            Files.copy(audio, dir.resolve("audio.ac3"))
            Files.writeString(dir.resolve("subs.vtt"), "WEBVTT\n\n00:00:01.000 --> 00:00:03.000\nHello\n")
            for ((name, segment) in listOf("audio" to "audio.ac3", "subs" to "subs.vtt")) {
                Files.writeString(
                    dir.resolve("$name.m3u8"),
                    "#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:5\n#EXT-X-PLAYLIST-TYPE:VOD\n#EXTINF:4.8,\n$segment\n#EXT-X-ENDLIST\n",
                )
            }
            val master = dir.resolve("master.m3u8")
            Files.writeString(
                master,
                "#EXTM3U\n" +
                    "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",NAME=\"English\",LANGUAGE=\"en\",DEFAULT=YES,AUTOSELECT=YES,URI=\"subs.m3u8\"\n" +
                    "#EXT-X-STREAM-INF:BANDWIDTH=64000,CODECS=\"ac-3\",SUBTITLES=\"subs\"\naudio.m3u8\n",
            )
            val reports = Reports()
            engine.setListener(reports)
            engine.startWithoutWindow()
            val id = engine.load(LoadRequest(url = master.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            val loaded = reports.await("the stream's subtitle track") { it.loadId == id && it.tracks.any { t -> t.kind == TrackKind.SUBTITLE } }
            engine.selectTrack(TrackKind.SUBTITLE, loaded.tracks.first { it.kind == TrackKind.SUBTITLE }.id)
            fun shown() = engine.properties(listOf("sub-text"))["sub-text"]
            reports.await("on the line") { it.loadId == id && it.positionSeconds in 1.6..2.8 }
            assertEquals("Hello", shown(), "the first pass")
            reports.await("past the line") { it.loadId == id && it.positionSeconds >= 3.3 }
            engine.seek(0.5, exact = true)
            reports.await("back on the line") { it.loadId == id && it.positionSeconds in 1.6..2.8 }
            assertEquals("Hello", shown(), "after the seek back")
        } finally {
            Files.deleteIfExists(audio)
            dir.toFile().deleteRecursively()
        }
    }

    /** A silent AC-3 file, 150 frames of 1536 samples at 48 kHz: 4.8 s. */
    private fun silentAc3(): Path {
        val frame = SILENT_AC3_FRAME.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
        val file = Files.createTempFile("silent", ".ac3")
        Files.write(file, ByteArray(frame.size * 150) { frame[it % frame.size] })
        return file
    }

    /**
     * mpv that couldn't start fails the load waiting for it and every later one (a retry, the next stream), each of
     * which would otherwise wait for an mpv that never comes.
     */
    @Test
    fun mpvThatCouldNotStartFailsEveryLoad() = assertEveryLoadFails(WindowlessHost(failure = "no display"))

    /** A video output that couldn't start fails the load waiting for it and every later one. */
    @Test
    fun aVideoOutputThatCouldNotStartFailsEveryLoad() = assertEveryLoadFails(WindowlessHost(bindError = "no GL context"))

    /** A video output that stops working during a playback (a frame it can't render) fails it and every later load. */
    @Test
    fun aVideoOutputFailingDuringPlaybackFailsItAndEveryLaterLoad() {
        val file = silentAc3()
        val host = WindowlessHost()
        val failing = MpvPlayerEngine(WINDOWLESS, host)
        try {
            val reports = Reports()
            failing.setListener(reports)
            failing.startWithoutWindow()
            val first = failing.load(LoadRequest(url = file.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            reports.await("the file loaded") { it.loadId == first && it.loaded }
            checkNotNull(host.onVideoReady)("framebuffer incomplete")
            reports.await("the playing file's error") { it.loadId == first && it.error != null }
            val next = failing.load(LoadRequest(url = file.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            reports.await("the next load's error") { it.loadId == next && it.error != null }
        } finally {
            failing.release()
            failing.awaitReleased(10.seconds)
            Files.deleteIfExists(file)
        }
    }

    /**
     * What fails on the engine's thread as it hands out mpv's events (here the listener, as the file loads) is logged
     * and the thread goes on: else the playback, and every later call, would stop with it.
     */
    @Test
    fun aListenerFailingOnAnEventLeavesTheEngineRunning() {
        val file = silentAc3()
        try {
            val thrown = CountDownLatch(1)
            engine.setListener(object : PlayerEngineListener {
                override fun onState(state: EngineState) {
                    if (state.loaded && thrown.count > 0) {
                        thrown.countDown()
                        error("the listener failed")
                    }
                }
            })
            engine.startWithoutWindow()
            engine.load(LoadRequest(url = file.toString(), options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
            assertTrue(thrown.await(20, TimeUnit.SECONDS), "never loaded: ${engine.currentState}")
            assertEquals(file.toString(), engine.properties(listOf("path"))["path"], "the engine's thread stopped")
        } finally {
            Files.deleteIfExists(file)
        }
    }

    /** Two loads in turn on an engine with [host], each failing. */
    private fun assertEveryLoadFails(host: WindowlessHost) {
        val failing = MpvPlayerEngine(WINDOWLESS, host)
        try {
            val reports = Reports()
            failing.setListener(reports)
            failing.startWithoutWindow()
            for (n in 1..2) {
                val id = failing.load(LoadRequest(url = "/missing.mkv", options = PlaybackOptions.of(DeviceSettings.DEFAULT, HardwareDecoder.LINUX)))
                reports.await("load $n's error") { it.loadId == id && it.error != null }
            }
        } finally {
            failing.release()
            failing.awaitReleased(10.seconds)
        }
    }

    /** The states an engine publishes, in order. */
    private class Reports : PlayerEngineListener {
        private val states = LinkedBlockingQueue<EngineState>()

        override fun onState(state: EngineState) {
            states += state
        }

        /** The first state from now on that [matches], within 20 s. */
        fun await(what: String, matches: (EngineState) -> Boolean): EngineState {
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(20)
            while (true) {
                val state = states.poll(deadline - System.nanoTime(), TimeUnit.NANOSECONDS) ?: fail("$what: none within 20 s")
                if (matches(state)) return state
            }
        }
    }

    /**
     * `vo=null` needs no window: nothing to attach or let go of. [failure] fails mpv's start (the host's options),
     * [bindError] the video output as it binds; [onVideoReady] is the engine's, once bound.
     */
    private class WindowlessHost(private val failure: String? = null, private val bindError: String? = null) : VideoHost {
        override val hardwareDecoder = HardwareDecoder.LINUX
        @Volatile var onVideoReady: ((String?) -> Unit)? = null

        override fun attach(window: java.awt.Window, onReady: () -> Unit): Boolean {
            onReady()
            return true
        }

        override fun options(): Map<String, String> {
            failure?.let(::error)
            return emptyMap()
        }

        override fun bind(core: MpvCore, onVideoReady: (error: String?) -> Unit) {
            this.onVideoReady = onVideoReady
            onVideoReady(bindError)
        }

        override fun unbind(core: MpvCore) = Unit

        override fun awaitUnbound(): Boolean = true

        override fun close() = Unit

        @Composable
        override fun Content(modifier: Modifier) = Unit
    }

    private companion object {
        val WINDOWLESS = MpvEngineOptions(extraOptions = mapOf("vo" to "null", "ao" to "null"))

        /** One AC-3 frame of stereo silence at 48 kHz and 32 kb/s (FFmpeg's encoder): every frame of a silent track. */
        const val SILENT_AC3_FRAME =
            "0b773f11004043e106f00108080821010104571f3e7cf9f3e7cf9f3e7cfbfe757cf9f3e7cf9f3e7cf8ff9d5f3e7cf9f3e7cf9f3e32fede" +
                "4c99200000f1e35ad680035ac3000000078f1ad6b4001ad6180000003c78d6b5a000d6b0c0000001e3c6b5ad0006b5860000000f1e35" +
                "ad680035ac3000000078f1ad6b4001ad60e48e"
    }
}
