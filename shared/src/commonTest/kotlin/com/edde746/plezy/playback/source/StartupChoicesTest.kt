package com.edde746.plezy.playback.source

import com.edde746.plezy.backend.TranscodeQualityPreset
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes

class StartupChoicesTest {
    // Resume position precedence: explicit request > shuffle from the beginning > offline progress > server offset.

    @Test
    fun anExplicitRequestWinsOverEveryOtherSource() {
        assertEquals(
            7.minutes,
            resolveOpenResumePosition(requested = 7.minutes, shuffleFromBeginning = true, offlineOffsetMs = 60_000, viewOffsetMs = 120_000),
        )
    }

    @Test
    fun aShuffleFromTheBeginningReturnsZeroEvenWithStoredOffsets() {
        assertEquals(Duration.ZERO, resolveOpenResumePosition(shuffleFromBeginning = true, offlineOffsetMs = 60_000, viewOffsetMs = 120_000))
    }

    @Test
    fun offlineProgressBeatsTheServerViewOffset() {
        assertEquals(1.minutes, resolveOpenResumePosition(offlineOffsetMs = 60_000, viewOffsetMs = 120_000))
    }

    @Test
    fun fallsBackToTheServerViewOffset() {
        assertEquals(2.minutes, resolveOpenResumePosition(viewOffsetMs = 120_000))
    }

    @Test
    fun returnsNullWhenNothingIsKnown() {
        assertNull(resolveOpenResumePosition())
        assertNull(resolveOpenResumePosition(offlineOffsetMs = 0))
    }

    // Startup quality.

    private fun startup(
        requested: TranscodeQualityPreset? = null,
        offlineLibraryMode: Boolean = false,
        live: Boolean = false,
        serverSupportsTranscoding: Boolean = true,
        onCellularOnly: Boolean = false,
        cellularDefault: TranscodeQualityPreset? = null,
        generalDefault: TranscodeQualityPreset = TranscodeQualityPreset.P720_2MBPS,
    ) = QualityChoice.atStartup(requested, offlineLibraryMode, live, serverSupportsTranscoding, onCellularOnly, cellularDefault, generalDefault)

    @Test
    fun aPerPlayPickWinsAndIsExplicit() {
        val choice = startup(requested = TranscodeQualityPreset.P1080_8MBPS, onCellularOnly = true, cellularDefault = TranscodeQualityPreset.P240_320)
        assertEquals(TranscodeQualityPreset.P1080_8MBPS, choice.preset)
        assertTrue(choice.explicit)
        assertFalse(choice.downloadOutranksQuality)
    }

    @Test
    fun theSavedDefaultIsNotExplicitSoADownloadOutranksIt() {
        val choice = startup()
        assertEquals(TranscodeQualityPreset.P720_2MBPS, choice.preset)
        assertTrue(choice.downloadOutranksQuality)
    }

    @Test
    fun theCellularDefaultAppliesOnACellularOnlyConnection() {
        assertEquals(TranscodeQualityPreset.P240_320, startup(onCellularOnly = true, cellularDefault = TranscodeQualityPreset.P240_320).preset)
    }

    @Test
    fun aServerThatCannotTranscodeStartsAtOriginal() {
        assertEquals(TranscodeQualityPreset.ORIGINAL, startup(serverSupportsTranscoding = false).preset)
    }

    @Test
    fun liveTvHonoursTheSavedDefaultWhateverTheServerReports() {
        assertEquals(TranscodeQualityPreset.P720_2MBPS, startup(live = true, serverSupportsTranscoding = false).preset)
    }

    @Test
    fun theOfflineLibraryStartsAtOriginal() {
        val choice = startup(offlineLibraryMode = true)
        assertEquals(TranscodeQualityPreset.ORIGINAL, choice.preset)
        assertFalse(choice.explicit)
    }

    @Test
    fun aQualityPickedInThePlayerStaysExplicit() {
        val picked = startup().picked(TranscodeQualityPreset.ORIGINAL)
        assertEquals(TranscodeQualityPreset.ORIGINAL, picked.preset)
        assertFalse(picked.downloadOutranksQuality)
    }
}
