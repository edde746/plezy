package com.edde746.plezy.mpv.video.hdr

import com.edde746.plezy.mpv.video.hdr.OutputColour.Result
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

/**
 * Nothing about the transaction is visible on screen: a renamed property, a reversed order or a rollback that claims
 * success without restoring all leave working-looking video while the committed surface description lies. So the
 * assertions are on the recorded (name, value) stream as well as the result.
 */
class OutputColourTest {
    /** Stands in for mpv: records every write in order and refuses the ones at the scripted positions. */
    private class Core {
        val writes = mutableListOf<Pair<String, String>>()
        val refusals = mutableSetOf<Int>()
        var commandable = true

        fun forget() {
            writes.clear()
            refusals.clear()
        }
    }

    private val core = Core()
    private val output = OutputColour(
        write = { name, value ->
            val position = core.writes.size
            core.writes += name to value
            if (position in core.refusals) MPV_ERROR_PROPERTY_ERROR else 0
        },
        canCommand = { core.commandable },
    )

    /** A real HDR state first, so rollbacks restore values mpv held rather than the all-"auto" defaults. */
    private fun applyPqBaseline() {
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 0))
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)
        core.forget()
    }

    /** Leaves the output state unknown: a forced-SDR reset refused on its first step, after one write landed. */
    private fun makeTheStateUnknown() {
        applyPqBaseline()
        core.refusals += listOf(2, 3, 4)
        assertEquals(Result.UNKNOWN, output.apply(SourceTransfer.SDR, 203))
    }

    @Test
    fun anHdrRequestWritesTheFourPropertiesPeakLast() {
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 0))
        assertEquals(
            listOf("target-trc" to "pq", "target-prim" to "bt.2020", "tone-mapping" to "auto", "target-peak" to "auto"),
            core.writes,
        )
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)
    }

    /** A peak inside mpv's 10..10000 is named; the operator stays mpv's own while the target is HDR. */
    @Test
    fun anHdrRequestWithADisplayPeakNamesThatPeak() {
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.HLG, 1000))
        assertEquals(
            listOf(
                "target-trc" to "hlg",
                "target-prim" to "bt.2020",
                "tone-mapping" to "auto",
                "target-peak" to "1000",
            ),
            core.writes,
        )
        assertEquals(listOf("hlg", "bt.2020", "auto", "1000"), output.applied)
    }

    /** BT.2020 primaries left standing under an SDR curve is neither SDR nor HDR. */
    @Test
    fun anSdrRequestWithdrawsEveryHdrProperty() {
        applyPqBaseline()
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.SDR, 0))
        assertEquals(
            listOf("target-trc" to "auto", "target-prim" to "auto", "tone-mapping" to "auto", "target-peak" to "auto"),
            core.writes,
        )
        assertEquals(listOf("auto", "auto", "auto", "auto"), output.applied)
    }

    /** The SDR fallback maps to the compositor's reference white in sRGB with mobius, and only it uses mobius. */
    @Test
    fun anSdrRequestWithAReferenceWhiteNamesTheMeasuredTerms() {
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.SDR, 203))
        assertEquals(
            listOf("target-trc" to "srgb", "target-prim" to "auto", "tone-mapping" to "mobius", "target-peak" to "203"),
            core.writes,
        )
        assertEquals(listOf("srgb", "auto", "mobius", "203"), output.applied)
    }

    /** A request for the state in force writes nothing, but one differing in a single value is never skipped. */
    @Test
    fun anIdenticalRequestIsSkippedButANarrowlyDifferentOneIsNot() {
        applyPqBaseline()
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 0))
        assertTrue(core.writes.isEmpty())

        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 1000))
        assertEquals(
            listOf("target-trc" to "pq", "target-prim" to "bt.2020", "tone-mapping" to "auto", "target-peak" to "1000"),
            core.writes,
        )
        assertEquals(listOf("pq", "bt.2020", "auto", "1000"), output.applied)

        core.forget()
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.HLG, 1000))
        assertEquals(
            listOf(
                "target-trc" to "hlg",
                "target-prim" to "bt.2020",
                "tone-mapping" to "auto",
                "target-peak" to "1000",
            ),
            core.writes,
        )
        assertEquals(listOf("hlg", "bt.2020", "auto", "1000"), output.applied)
    }

    /** A refused step restores what landed, newest first, to the values mpv held, and says the old state stands. */
    @Test
    fun aRefusedStepUnwindsNewestFirstAndReportsRestored() {
        applyPqBaseline()
        core.refusals += 2
        assertEquals(Result.RESTORED, output.apply(SourceTransfer.SDR, 203))
        assertEquals(
            listOf(
                "target-trc" to "srgb",
                "target-prim" to "auto",
                "tone-mapping" to "mobius",
                "target-prim" to "bt.2020",
                "target-trc" to "pq",
            ),
            core.writes,
        )
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)
    }

    /** A refused unwind leaves a colour space nobody can name, so every property goes to "auto". */
    @Test
    fun aRefusedRollbackForcesSdr() {
        applyPqBaseline()
        core.refusals += listOf(2, 3)
        assertEquals(Result.FORCED_SDR, output.apply(SourceTransfer.SDR, 203))
        assertEquals(
            listOf(
                "target-trc" to "srgb",
                "target-prim" to "auto",
                "tone-mapping" to "mobius",
                "target-prim" to "bt.2020",
                "target-trc" to "auto",
                "target-prim" to "auto",
                "tone-mapping" to "auto",
                "target-peak" to "auto",
            ),
            core.writes,
        )
        assertEquals(listOf("auto", "auto", "auto", "auto"), output.applied)
    }

    /** "auto" refused means mpv takes no orders: the reset stops, and only the steps that landed are recorded. */
    @Test
    fun aRefusedForcedSdrReportsUnknown() {
        applyPqBaseline()
        core.refusals += listOf(2, 3, 5)
        assertEquals(Result.UNKNOWN, output.apply(SourceTransfer.SDR, 203))
        assertEquals(
            listOf(
                "target-trc" to "srgb",
                "target-prim" to "auto",
                "tone-mapping" to "mobius",
                "target-prim" to "bt.2020",
                "target-trc" to "auto",
                "target-prim" to "auto",
            ),
            core.writes,
        )
        assertEquals(listOf("auto", "bt.2020", "auto", "auto"), output.applied)
    }

    /**
     * After a reset refused before it recorded anything, the cache still names the baseline while mpv holds the sRGB
     * curve that landed first. The baseline's own request must then write rather than be answered from the cache.
     */
    @Test
    fun anUnknownOutputStateIsNeverAnsweredFromTheCache() {
        makeTheStateUnknown()
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)

        val before = core.writes.size
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 0))
        assertTrue(core.writes.size > before)
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)

        // The clean apply made the state known again, so the same request is skipped once more.
        val after = core.writes.size
        assertEquals(Result.APPLIED, output.apply(SourceTransfer.PQ, 0))
        assertEquals(after, core.writes.size)
    }

    /** Unwinding nothing is a clean unwind, but "where it was" is unknown, so it must not claim RESTORED. */
    @Test
    fun aRefusalAfterAnUnknownStateIsNotReportedAsRestored() {
        makeTheStateUnknown()
        core.refusals += 5
        val result = output.apply(SourceTransfer.PQ, 0)
        assertNotEquals(Result.RESTORED, result)
        assertEquals(Result.UNKNOWN, result)
    }

    /** A core that can no longer be commanded writes nothing and owes the same answer about the unknown state. */
    @Test
    fun anUncommandableCoreInheritsTheUnknownState() {
        makeTheStateUnknown()
        core.commandable = false
        val before = core.writes.size
        assertEquals(Result.UNKNOWN, output.apply(SourceTransfer.PQ, 0))
        assertEquals(before, core.writes.size)
    }

    /** With the state known, an uncommandable core leaves it standing: nothing was touched. */
    @Test
    fun anUncommandableCoreReportsAKnownStateRestored() {
        applyPqBaseline()
        core.commandable = false
        assertEquals(Result.RESTORED, output.apply(SourceTransfer.SDR, 203))
        assertTrue(core.writes.isEmpty())
        assertEquals(listOf("pq", "bt.2020", "auto", "auto"), output.applied)
    }

    private companion object {
        /** mpv's MPV_ERROR_PROPERTY_ERROR. */
        const val MPV_ERROR_PROPERTY_ERROR = -10
    }
}
