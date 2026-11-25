package com.edde746.plezy.presentation.player

import com.edde746.plezy.model.cleanSubtitleTitle
import com.edde746.plezy.playback.Track
import com.edde746.plezy.playback.TrackKind
import kotlin.test.Test
import kotlin.test.assertEquals

/** The audio menu names a track by its codec's profile, so a lossless track and its lossy core read differently. */
class TrackLabelsTest {
    private fun audio(id: Long, codec: String, profile: String?, channels: Int) =
        Track(id, TrackKind.AUDIO, null, null, codec, selected = false, external = false, channels = channels, codecProfile = profile)

    @Test
    fun audioRowsNameTheCodecByItsProfile() {
        val tracks = listOf(
            audio(1, "dts", "DTS-HD MA", 8),
            audio(2, "dts", "DTS", 6),
            audio(3, "dts", "DTS-HD MA + DTS:X", 8),
            audio(4, "truehd", "Dolby TrueHD + Dolby Atmos", 8),
            audio(5, "eac3", "Dolby Digital Plus + Dolby Atmos", 6),
            audio(6, "eac3", null, 6),
            audio(7, "aac", "LC", 2),
        )
        assertEquals(
            listOf("DTS-HD MA · 7.1", "DTS · 5.1", "DTS-HD MA + DTS:X · 7.1", "TrueHD Atmos · 7.1", "E-AC3 Atmos · 5.1", "E-AC3 · 5.1", "AAC · Stereo"),
            TrackLabels.items(tracks, TrackKind.AUDIO, selectedId = null, secondId = null, locale = "en").map { it.detail },
        )
    }

    @Test
    fun anExternalSubtitleNamesItsCodecAndExternalOnce() {
        val title = cleanSubtitleTitle("English - SUBRIP - External", "subrip")
        val tracks = listOf(Track(1, TrackKind.SUBTITLE, title, "eng", "subrip", selected = false, external = true))
        val row = TrackLabels.items(tracks, TrackKind.SUBTITLE, selectedId = null, secondId = null, locale = "en").last()
        assertEquals("English", row.label)
        assertEquals("SRT · External", row.detail)
    }
}
