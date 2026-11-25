package com.edde746.plezy.mpv

import com.edde746.plezy.music.engine.AudioEvent
import com.edde746.plezy.music.engine.AudioMedia
import com.edde746.plezy.music.engine.AudioPlayer
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.math.PI
import kotlin.math.roundToInt
import kotlin.math.sin
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.withTimeout

/**
 * The music player on this machine's libmpv, muted: two consecutive tracks play gaplessly. The first opens near its
 * end with the second armed (`setNext`); mpv advances into the second without a new open, the player reports the
 * transition with the second's URI, the first's last position is its end, and the second plays on from 0. The tracks
 * are the two URLs of `plezy.audio.urls` (each fetched with a header of its own entry), else two WAV files of the
 * same format written here.
 */
class AudioPlayerGaplessTest {
    private val player: AudioPlayer = desktopAudioPlayer(mapOf("mute" to "yes"))
    private val events = CopyOnWriteArrayList<Pair<TimeSource.Monotonic.ValueTimeMark, AudioEvent>>()
    private val flow = MutableSharedFlow<AudioEvent>(extraBufferCapacity = 1024)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val written = mutableListOf<Path>()

    init {
        scope.launch {
            player.events.collect {
                events += TimeSource.Monotonic.markNow() to it
                flow.emit(it)
            }
        }
    }

    @AfterTest
    fun stop() = runBlocking {
        player.dispose()
        scope.cancel()
        written.forEach(Files::deleteIfExists)
    }

    @Test
    fun twoConsecutiveTracksPlayGaplessly() = runBlocking {
        val urls = System.getProperty("plezy.audio.urls")?.split(',')?.filter { it.isNotBlank() }
        val (first, second) = urls?.takeLast(2) ?: listOf(sine(440.0), sine(660.0))
        val headers = if (urls != null) mapOf("X-Plex-Product" to "Plezy") else emptyMap()
        println("gapless: $first then $second")

        // Listening before the open: from a local file the length can come before the open returns.
        val length = async(start = CoroutineStart.UNDISPATCHED) {
            flow.first { it is AudioEvent.DurationChanged && it.duration > Duration.ZERO } as AudioEvent.DurationChanged
        }
        player.open(AudioMedia(first, headers))
        val duration = withTimeout(20.seconds) { length.await() }.duration
        player.setNext(AudioMedia(second, headers))
        val lead = 3.seconds
        player.seek(duration - lead)
        val seekedAt = TimeSource.Monotonic.markNow()

        val transition = withTimeout(lead + 10.seconds) { flow.first { it is AudioEvent.TrackTransition } }
        val toBoundary = seekedAt.elapsedNow()
        assertEquals(AudioEvent.TrackTransition(second), transition)
        val outgoing = checkNotNull(player.outgoingSourcePosition) { "no outgoing position" }
        println("gapless: first track $duration; boundary ${toBoundary.inWholeMilliseconds} ms after the seek to ${duration - lead}; outgoing $outgoing")
        // mpv moves to the next entry as its decoder does, while the output's buffer still plays the first's last
        // moments: its last report is that close to the end.
        assertTrue(outgoing >= duration - 2.seconds, "the first track played to its end: $outgoing of $duration")
        // The boundary came when the first track's rest had played out: no stall and no reopen at the boundary.
        assertTrue(toBoundary <= lead + 2.seconds, "the boundary took $toBoundary for $lead of audio")

        // The second track plays on from 0 at the playback rate.
        withTimeout(10.seconds) { flow.first { it is AudioEvent.Position && it.position >= 2.seconds } }
        val transitionAt = events.first { it.second == transition }.first
        val after = events.filter { it.first > transitionAt }.map { it.second }
        val positions = after.filterIsInstance<AudioEvent.Position>().map { it.position }
        println("gapless: after the boundary ${positions.take(12)}")
        assertTrue(positions.first() <= 1.seconds, "the second track starts at 0: ${positions.first()}")
        assertEquals(positions.sorted(), positions, "the second track's position runs forward")
        assertTrue(after.none { it is AudioEvent.Error || it is AudioEvent.TrackTransition }, "after the boundary: $after")
        assertTrue(player.state.playing, "playing on")
    }

    /** A 6-s 48 kHz stereo WAV of a [frequency] tone, both tracks in the one format mpv splices without a gap. */
    private fun sine(frequency: Double): String {
        val rate = 48_000
        val frames = rate * 6
        val data = ByteBuffer.allocate(frames * 4).order(ByteOrder.LITTLE_ENDIAN)
        repeat(frames) { i ->
            val sample = (sin(2 * PI * frequency * i / rate) * 8000).roundToInt().toShort()
            data.putShort(sample).putShort(sample)
        }
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
            .put("RIFF".toByteArray()).putInt(36 + data.capacity()).put("WAVE".toByteArray())
            .put("fmt ".toByteArray()).putInt(16).putShort(1).putShort(2).putInt(rate).putInt(rate * 4).putShort(4).putShort(16)
            .put("data".toByteArray()).putInt(data.capacity())
        val file = Files.createTempFile("plezy-gapless-", ".wav")
        Files.write(file, header.array() + data.array())
        written.add(file)
        return file.toString()
    }
}
