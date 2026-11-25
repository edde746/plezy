package com.edde746.plezy.playback.session

import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class SpuriousEofRecoveryTest {
    // An episode whose selected video and audio end at 2933.68 s of a 3019.58 s container whose dub tracks run on.
    private val durationMillis = 3_019_584L
    private val positionMillis = 2_933_680L
    private val fileBytes = 12_572_719_464L

    private val reloads = mutableListOf<Double>()
    private var parks = 0

    private fun TestScope.recovery(outcome: ReloadOutcome = ReloadOutcome.OPENED) =
        SpuriousEofRecovery(backgroundScope, { at -> reloads += at; outcome }, { parks++ })

    private fun shortEof(
        fileSize: Long? = fileBytes,
        fileFormat: String? = "mkv",
        transcoding: Boolean = false,
        transportFault: Boolean = false,
        serverStopped: Boolean = false,
    ) = EofReport(positionMillis, durationMillis, durationMillis, null, transcoding, transportFault, fileSize, fileFormat, serverStopped)

    @Test
    fun aShortEndOfASizedDirectPlayFileWithNoTransportFaultIsTheRealEnd() = runTest {
        val recovery = recovery()
        assertFalse(recovery.interceptEof(shortEof()))
        runCurrent()
        assertEquals(emptyList(), reloads)
        assertFalse(recovery.parked)
    }

    @Test
    fun aShortEndAfterATransportFaultRecoversThenParks() = runTest {
        val recovery = recovery()
        repeat(SpuriousEofRecovery.MAX_ATTEMPTS) { attempt ->
            assertTrue(recovery.interceptEof(shortEof(transportFault = true)))
            runCurrent()
            assertEquals(attempt + 1, reloads.size)
            assertFalse(recovery.parked)
        }
        assertTrue(recovery.interceptEof(shortEof(transportFault = true)))
        runCurrent()
        assertEquals(SpuriousEofRecovery.MAX_ATTEMPTS, reloads.size)
        assertTrue(recovery.parked)
        assertEquals(1, parks)
        assertTrue(recovery.interceptEof(shortEof(transportFault = true)), "a parked stream swallows more ends")
        assertEquals(1, parks)
    }

    @Test
    fun aStreamTheServerStoppedParksAndAViewerRetryStillRebuildsIt() = runTest {
        val recovery = recovery()
        assertTrue(recovery.interceptEof(shortEof(transportFault = true, serverStopped = true)))
        runCurrent()
        assertEquals(emptyList(), reloads)
        assertTrue(recovery.parked)
        recovery.retry(positionMillis / 1000.0)
        runCurrent()
        assertEquals(listOf(positionMillis / 1000.0), reloads)
        assertFalse(recovery.parked)
    }

    @Test
    fun aFailedRecoveryParks() = runTest {
        val recovery = recovery(ReloadOutcome.FAILED)
        assertTrue(recovery.interceptEof(shortEof(transportFault = true)))
        runCurrent()
        assertTrue(recovery.parked)
    }

    @Test
    fun progressPastTheRecoveryPointGivesTheBudgetBack() = runTest {
        val recovery = recovery()
        repeat(SpuriousEofRecovery.MAX_ATTEMPTS) { recovery.interceptEof(shortEof(transportFault = true)) }
        recovery.onPositionAdvanced(positionMillis + SpuriousEofRecovery.PROGRESS_RESET_MILLIS)
        assertTrue(recovery.interceptEof(shortEof(transportFault = true)))
        runCurrent()
        assertEquals(SpuriousEofRecovery.MAX_ATTEMPTS + 1, reloads.size)
        assertFalse(recovery.parked)
    }

    @Test
    fun anUnsizedOrEmptyFileKeepsTheDurationRule() = runTest {
        for (size in listOf(null, 0L)) {
            reloads.clear()
            val recovery = recovery()
            assertTrue(recovery.interceptEof(shortEof(fileSize = size)), "file-size $size")
            runCurrent()
            assertEquals(listOf(positionMillis / 1000.0), reloads, "file-size $size")
        }
    }

    @Test
    fun aManifestPlayedDirectlyAnUnknownFormatOrATranscodeKeepsTheDurationRule() = runTest {
        for (eof in listOf(shortEof(fileFormat = "hls"), shortEof(fileFormat = null), shortEof(transcoding = true))) {
            reloads.clear()
            val recovery = recovery()
            assertTrue(recovery.interceptEof(eof), "$eof")
            runCurrent()
            assertEquals(listOf(positionMillis / 1000.0), reloads, "$eof")
        }
    }

    // Part 1 of a 50 + 40 minute stacked item, transcoded: the open file's own span decides.
    private fun partEof(positionMillis: Long) =
        EofReport(positionMillis, 5_400_000, 5_400_000, partEndMillis = 3_000_000, transcoding = true, transportFault = false, fileSizeBytes = null, fileFormat = null, serverStopped = false)

    @Test
    fun theOpenPartEndingAtItsOwnSpanIsTheRealEndOfThatFile() = runTest {
        assertFalse(recovery().interceptEof(partEof(3_000_000)))
        assertEquals(emptyList(), reloads)
    }

    @Test
    fun aStreamDyingInsideTheOpenPartRecoversThere() = runTest {
        assertTrue(recovery().interceptEof(partEof(1_800_000)))
        runCurrent()
        assertEquals(listOf(1800.0), reloads)
    }
}
