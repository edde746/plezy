package com.edde746.plezy.presentation.player

import com.edde746.plezy.backend.TranscodeQualityPreset
import com.edde746.plezy.input.PlayerCommand
import com.edde746.plezy.playback.session.QualityChoice
import com.edde746.plezy.playback.session.SessionInfo
import com.edde746.plezy.playback.session.VersionOption
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class VersionsTest {
    private fun label(preset: TranscodeQualityPreset, sourceKbps: Int? = null) = PlayerStates.qualityLabel(preset, sourceKbps)

    @Test
    fun theOriginalCarriesTheSourcesBitrateWhenKnown() {
        assertEquals("Original", label(TranscodeQualityPreset.ORIGINAL))
        assertEquals("Original 12.4 Mbps", label(TranscodeQualityPreset.ORIGINAL, 12400))
        assertEquals("Original", label(TranscodeQualityPreset.ORIGINAL, 0))
    }

    @Test
    fun presetsShowTheirHeightAndBitrate() {
        assertEquals("720p 2 Mbps", label(TranscodeQualityPreset.P720_2MBPS))
        assertEquals("720p 2 Mbps", label(TranscodeQualityPreset.P720_2MBPS, 12400), "the source's bitrate labels only the original")
        assertEquals("480p 1.5 Mbps", label(TranscodeQualityPreset.P480_1_5MBPS))
        assertEquals("1080p 10 Mbps", label(TranscodeQualityPreset.P1080_10MBPS))
        assertEquals("1080p 20 Mbps", label(TranscodeQualityPreset.P1080_20MBPS))
        assertTrue(label(TranscodeQualityPreset.P240_320).startsWith("240p "))
        assertTrue(label(TranscodeQualityPreset.P320_720).startsWith("320p "))
        for (preset in listOf(TranscodeQualityPreset.P1080_8MBPS, TranscodeQualityPreset.P1080_12MBPS)) {
            assertTrue(label(preset).startsWith("1080p "))
        }
        for (preset in listOf(TranscodeQualityPreset.P720_3MBPS, TranscodeQualityPreset.P720_4MBPS)) {
            assertTrue(label(preset).startsWith("720p "))
        }
    }

    @Test
    fun eachQualityRowShowsItsBitrateOverTheDuration() {
        val hour = 3_600_000L
        val menu = assertNotNull(
            PlayerStates.versions(
                SessionInfo(
                    title = "x",
                    quality = QualityChoice(selected = TranscodeQualityPreset.ORIGINAL, sourceBitrateKbps = 8000, sourceDurationMs = hour),
                ),
            ),
        )
        val details = menu.qualities.associate { (it.command as PlayerCommand.SelectQuality).preset to it.detail }
        assertEquals("≈ 3.4 GB", details[TranscodeQualityPreset.ORIGINAL])
        assertEquals("≈ 858 MB", details[TranscodeQualityPreset.P720_2MBPS])
        assertNull(PlayerStates.qualitySize(TranscodeQualityPreset.P720_2MBPS, 8000, null), "a size needs the duration")
        assertNull(PlayerStates.qualitySize(TranscodeQualityPreset.ORIGINAL, null, hour), "the original's needs the source's bitrate")
        assertEquals("≈ 858 MB", PlayerStates.qualitySize(TranscodeQualityPreset.P720_2MBPS, null, hour))
    }

    @Test
    fun aLowerBitrateNeverReadsLargerThanTheOriginal() {
        // A 90 s episode of 405 kbps beside 240p at 320 kbps: one duration and each row's own bitrate.
        val duration = 90_021L
        assertEquals("≈ 4.3 MB", PlayerStates.qualitySize(TranscodeQualityPreset.ORIGINAL, 405, duration))
        assertEquals("≈ 3.4 MB", PlayerStates.qualitySize(TranscodeQualityPreset.P240_320, 405, duration))
    }

    @Test
    fun presetsTheSourceAlreadyFitsUnderAreNotOffered() {
        fun presets(selected: TranscodeQualityPreset, kbps: Int?, height: Int?) = assertNotNull(
            PlayerStates.versions(
                SessionInfo(
                    title = "x",
                    quality = QualityChoice(selected, sourceBitrateKbps = kbps, sourceDurationMs = 3_600_000L, sourceHeightPx = height),
                ),
            ),
        ).qualities.map { (it.command as PlayerCommand.SelectQuality).preset }
        assertEquals(
            listOf(TranscodeQualityPreset.ORIGINAL),
            presets(TranscodeQualityPreset.ORIGINAL, 300, 180),
            "a 180p source at 300 kbps fits under every preset: Original alone",
        )
        val sd = presets(TranscodeQualityPreset.ORIGINAL, 1200, 480)
        assertTrue(TranscodeQualityPreset.P480_1_5MBPS !in sd, "480p 1.5 Mbps is at the source's height and above its bitrate")
        assertTrue(TranscodeQualityPreset.P1080_20MBPS !in sd)
        assertTrue(TranscodeQualityPreset.P320_720 in sd, "below the source's height stays")
        val hd = presets(TranscodeQualityPreset.ORIGINAL, 5000, 1080)
        assertTrue(TranscodeQualityPreset.P1080_8MBPS !in hd)
        assertTrue(TranscodeQualityPreset.P720_4MBPS in hd, "a lower height stays, whatever its bitrate")
        assertTrue(TranscodeQualityPreset.P1080_8MBPS in presets(TranscodeQualityPreset.P1080_8MBPS, 5000, 1080), "the preset playing stays ticked")
        assertEquals(TranscodeQualityPreset.displayOrder, presets(TranscodeQualityPreset.ORIGINAL, null, 1080), "without the source's bitrate every preset stays")
        assertEquals(TranscodeQualityPreset.displayOrder, presets(TranscodeQualityPreset.ORIGINAL, 5000, null), "without its height too")
    }

    @Test
    fun nothingToChooseHasNoSheet() {
        assertNull(PlayerStates.versions(SessionInfo(title = "x")))
        assertNull(PlayerStates.versions(SessionInfo(title = "x", versions = listOf(VersionOption("1080p")))))
    }

    @Test
    fun theSheetTicksTheVersionAndQualityPlayingAndPicksReopen() {
        val menu = assertNotNull(
            PlayerStates.versions(
                SessionInfo(
                    title = "x",
                    versions = listOf(VersionOption("4K · HEVC", "a.mkv"), VersionOption("1080p · H.264", "b.mkv")),
                    versionIndex = 1,
                    quality = QualityChoice(
                        selected = TranscodeQualityPreset.P720_4MBPS,
                        sourceBitrateKbps = 8500,
                    ),
                ),
            ),
        )
        assertTrue(menu.showsVersions)
        assertEquals(listOf(false, true), menu.versions.map { it.selected })
        assertEquals("a.mkv", menu.versions[0].detail)
        assertEquals(PlayerCommand.SelectVersion(0), menu.versions[0].command)
        val expected = PlayerStates.qualities(8500, TranscodeQualityPreset.P720_4MBPS)
        assertEquals(expected.map { it.label }, menu.qualities.map { it.label }, "the list every version and quality choice shows")
        assertEquals("Original 8.5 Mbps", menu.qualities[0].label)
        assertEquals(expected.map { it.selected }, menu.qualities.map { it.selected })
        assertEquals("720p 4 Mbps", menu.qualities.single { it.selected }.label)
        assertEquals(PlayerCommand.SelectQuality(TranscodeQualityPreset.ORIGINAL), menu.qualities[0].command)
    }

    @Test
    fun theOptionsRowShowsTheQualityPlayingAndOneVersionHidesItsColumn() = playerTest {
        playing()
        sessionInfo {
            it.copy(
                versions = listOf(VersionOption("1080p")),
                quality = QualityChoice(TranscodeQualityPreset.ORIGINAL),
            )
        }
        val menu = assertNotNull(state.versions)
        assertFalse(menu.showsVersions)
        val row = assertNotNull(state.options.firstOrNull { it.id == PlayerOptionId.VERSIONS })
        assertEquals("Original", row.value)
        assertEquals(PlayerOptionId.ZOOM, state.options[state.options.indexOf(row) - 1].id, "after the zoom")
        dispatch(PlayerCommand.SelectQuality(TranscodeQualityPreset.P720_2MBPS))
        assertEquals("quality P720_2MBPS", session.actions.last())
    }
}
