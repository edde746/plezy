package com.edde746.plezy.mpv

import com.edde746.plezy.playback.AudioInfo
import com.edde746.plezy.playback.EngineState
import kotlin.test.Test
import kotlin.test.assertEquals

class PlaybackDiagnosticsTest {
    @Test
    fun aPlaybacksStateIsKeptAsItsAllowlistedValues() {
        val state = EngineState(loaded = true, audio = AudioInfo("truehd", 8, 48_000), hwdec = "mediacodec", audioPassthrough = true)
        assertEquals(
            PlaybackDiagnostics.Snapshot("audio:truehd", 8, 48_000, "mediacodec", passthrough = true, downmix = false, normalization = true),
            PlaybackDiagnostics.Snapshot.of(state, normalization = true, downmix = false),
        )
    }

    @Test
    fun valuesOutOfTheirRangesAreLeftOutAndAnOddDecoderIsUnknown() {
        val state = EngineState(loaded = true, audio = AudioInfo("opus", 0, 1_000_000), hwdec = "media codec/../x")
        val snapshot = PlaybackDiagnostics.Snapshot.of(state, normalization = false, downmix = true)
        assertEquals("audio:other", snapshot.codecContext)
        assertEquals(null, snapshot.channelCount)
        assertEquals(null, snapshot.sampleRate)
        assertEquals("unknown", snapshot.decoder)
    }

    @Test
    fun mpvsCodecNamesMapToTheReportsCodecs() {
        val codecs = listOf("aac", "ac3", "eac3", "dts", "mlp", "flac", "pcm_s24le", "vorbis")
        assertEquals(
            listOf("audio:aac", "audio:ac3", "audio:eac3", "audio:dts", "audio:truehd", "audio:flac", "audio:pcm", "audio:other"),
            codecs.map(PlaybackDiagnostics.Snapshot::codecContext),
        )
    }
}
