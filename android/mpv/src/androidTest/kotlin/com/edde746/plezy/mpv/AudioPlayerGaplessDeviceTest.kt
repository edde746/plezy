package com.edde746.plezy.mpv

import android.util.Log
import androidx.test.platform.app.InstrumentationRegistry
import com.edde746.plezy.music.engine.AudioEvent
import com.edde746.plezy.music.engine.AudioMedia
import com.edde746.plezy.music.engine.AudioPlayer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout
import org.junit.After
import org.junit.Before
import org.junit.Test
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * The music player on real libmpv, muted: two consecutive tracks play gaplessly. The first opens near its end with the
 * second armed (`setNext`); mpv advances into the second without a new open, the player reports the transition with
 * the second's URI, the first's last position is its end, and the second plays on from 0. The tracks are two tones of
 * one format the test writes to the app's cache, so it needs no media from the run.
 */
class AudioPlayerGaplessDeviceTest {
    private lateinit var player: AudioPlayer
    private val written = mutableListOf<File>()
    private val events = CopyOnWriteArrayList<Pair<TimeSource.Monotonic.ValueTimeMark, AudioEvent>>()
    private val flow = MutableSharedFlow<AudioEvent>(extraBufferCapacity = 1024)
    private val scope = CoroutineScope(Dispatchers.Default)

    @Before
    fun start() {
        player = androidAudioPlayer(InstrumentationRegistry.getInstrumentation().targetContext, mapOf("mute" to "yes"))
        scope.launch {
            player.events.collect {
                events += TimeSource.Monotonic.markNow() to it
                flow.emit(it)
            }
        }
    }

    @After
    fun stop() = runBlocking {
        player.dispose()
        scope.cancel()
        written.forEach(File::delete)
    }

    @Test
    fun twoConsecutiveTracksPlayGaplessly() = runBlocking {
        val first = write("first.wav", tone(440.0))
        val second = write("second.wav", tone(660.0))
        // Listening before the open: from a local file the length can come before the open returns.
        val length = async(start = CoroutineStart.UNDISPATCHED) {
            flow.first { it is AudioEvent.DurationChanged && it.duration > Duration.ZERO } as AudioEvent.DurationChanged
        }
        player.open(AudioMedia(first))
        val duration = try {
            withTimeout(20.seconds) { length.await() }.duration
        } catch (e: TimeoutCancellationException) {
            throw AssertionError("no length within 20 s; events: ${events.map { it.second }}", e)
        }
        player.setNext(AudioMedia(second))
        val lead = 3.seconds
        player.seek(duration - lead)
        val seekedAt = TimeSource.Monotonic.markNow()

        val transition = withTimeout(lead + 10.seconds) { flow.first { it is AudioEvent.TrackTransition } }
        val toBoundary = seekedAt.elapsedNow()
        assertEquals(AudioEvent.TrackTransition(second), transition)
        val outgoing = checkNotNull(player.outgoingSourcePosition) { "no outgoing position" }
        Log.i(TAG, "first track $duration; boundary ${toBoundary.inWholeMilliseconds} ms after the seek to ${duration - lead}; outgoing $outgoing")
        // mpv moves to the next entry as its decoder does, while the output's buffer still plays the first's last
        // moments (about 1.5 s on Android's AudioTrack): its last report is that close to the end.
        assertTrue(outgoing >= duration - 2.seconds, "the first track played to its end: $outgoing of $duration")
        // The boundary came when the first track's rest had played out: no stall and no reopen at the boundary.
        assertTrue(toBoundary <= lead + 2.seconds, "the boundary took $toBoundary for $lead of audio")

        // The second track plays on from 0 at the playback rate.
        withTimeout(10.seconds) { flow.first { it is AudioEvent.Position && it.position >= 2.seconds } }
        val transitionAt = events.first { it.second == transition }.first
        val after = events.filter { it.first > transitionAt }.map { it.second }
        val positions = after.filterIsInstance<AudioEvent.Position>().map { it.position }
        Log.i(TAG, "after the boundary: ${positions.take(12)}")
        assertTrue(positions.first() <= 1.seconds, "the second track starts at 0: ${positions.first()}")
        assertEquals(positions.sorted(), positions, "the second track's position runs forward")
        assertTrue(after.none { it is AudioEvent.Error || it is AudioEvent.TrackTransition }, "after the boundary: $after")
        assertTrue(player.state.playing, "playing on")
    }

    /** [bytes] as [name] in the app's cache: its path. */
    private fun write(name: String, bytes: ByteArray): String {
        val file = File(InstrumentationRegistry.getInstrumentation().targetContext.cacheDir, name)
        file.writeBytes(bytes)
        written += file
        return file.absolutePath
    }

    private companion object {
        const val TAG = "AudioGaplessTest"

        /** A 6-s 48 kHz 16-bit stereo WAV of a [frequency] tone: both tracks in the one format mpv splices without a gap. */
        fun tone(frequency: Double): ByteArray {
            val rate = 48_000
            val frames = rate * 6
            val wav = ByteBuffer.allocate(44 + frames * 4).order(ByteOrder.LITTLE_ENDIAN)
            wav.put("RIFF".toByteArray()).putInt(36 + frames * 4).put("WAVE".toByteArray())
                .put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(2).putInt(rate).putInt(rate * 4).putShort(4).putShort(16)
                .put("data".toByteArray()).putInt(frames * 4)
            repeat(frames) { i ->
                val sample = (sin(2 * PI * frequency * i / rate) * 8000).roundToInt().toShort()
                wav.putShort(sample).putShort(sample)
            }
            return wav.array()
        }
    }
}
