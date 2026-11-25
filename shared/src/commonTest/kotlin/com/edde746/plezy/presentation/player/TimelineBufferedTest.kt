package com.edde746.plezy.presentation.player

import com.edde746.plezy.playback.mpv.MpvLifecycle
import kotlin.math.min
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.fail

/**
 * The seek bar's buffered part as mpv reports what it read, through an engine's [MpvLifecycle] to the store's timeline.
 * mpv sends `time-pos` at every frame and what its demuxer read with each cache update: every quarter second while it
 * reads, and once it has read the whole file only once the position moved a second since the last one. Its
 * `cache-duration` counts from the demuxer's reader, which runs ahead of the position by what the decoders hold.
 */
class TimelineBufferedTest {
    @Test
    fun theBufferedEndNeverFallsBackAndSitsAtTheEndOnceTheFileIsRead() = playerTest {
        val mpv = MpvLifecycle()
        val drawn = mutableListOf<Pair<Double, Float>>()

        fun publish() {
            val reported = mpv.publishable() ?: return
            engineState { reported }
            drawn += reported.positionSeconds to timeline.buffered
        }

        // mpv sends an engine only the properties it observes.
        fun double(name: String, value: Double) {
            if (name in MpvLifecycle.DOUBLES) mpv.double(name, value)
            publish()
        }

        fun text(name: String, value: String) {
            if (name in MpvLifecycle.TEXTS) mpv.text(name, value)
            publish()
        }

        mpv.load(1)
        mpv.startFile()
        mpv.fileLoaded()
        mpv.double("duration", DURATION)
        mpv.playbackRestart()
        publish()

        // A 20 s file read at three times the speed it plays: whole after 6 s.
        var position = 0.0
        var lastUpdate = -1.0
        while (position < 19.5) {
            position += 1 / 24.0
            double("time-pos", position)
            val readEnd = min(2.0 + 3 * position, LAST_PACKET)
            val eof = readEnd >= LAST_PACKET
            if (position - lastUpdate >= if (eof) 1.0 else 0.25) {
                lastUpdate = position
                val reader = position + 0.4
                double("demuxer-cache-duration", readEnd - reader)
                text(
                    "demuxer-cache-state",
                    """{"cache-end":$readEnd,"reader-pts":$reader,"cache-duration":${readEnd - reader},"eof":$eof,""" +
                        """"idle":$eof,"bof-cached":true,"eof-cached":$eof,"seekable-ranges":[{"start":0.0,"end":${readEnd - 0.5}}]}""",
                )
            }
        }

        drawn.zipWithNext().firstOrNull { (before, after) -> after.second < before.second }?.let { (before, after) ->
            fail("the buffered end fell back from ${before.second} at ${before.first} s to ${after.second} at ${after.first} s")
        }
        assertEquals(1f, drawn.last().second, "the whole file read: the buffered part reaches the end")
    }

    private companion object {
        const val DURATION = 20.05

        /** The timestamp of the file's last packet, short of its duration by the last frame. */
        const val LAST_PACKET = 20.0
    }
}
