package com.edde746.plezy.mpv.video.hdr

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotEquals
import kotlin.test.assertTrue

class HdrMetadataTest {
    /** PQ / BT.2020 unless a case says otherwise, since that is what the luminance rules are usually judged against. */
    private fun metadata(
        maxCll: Long,
        maxFall: Long,
        maxLuminance: Long,
        minLuminance: Double,
        transfer: SourceTransfer = SourceTransfer.PQ,
    ) = HdrMetadata(transfer, SourcePrimaries.BT2020, maxCll, maxFall, maxLuminance, minLuminance)

    private fun support(mastering: Boolean, version: Int, extendedTargetVolume: Boolean = false) =
        CompositorLuminanceSupport(mastering, extendedTargetVolume, version)

    private val hdrTransfers = listOf(SourceTransfer.PQ, SourceTransfer.HLG)

    /** Every gate passing, in compositor mode with no peak or reference reported. */
    private val allGatesPass =
        HdrInputs(allowed = true, clientCanDescribe = true, outputIsHdr = true, sourceDescribable = true)
    private val playerMode = allGatesPass.copy(requested = HdrToneMapping.PLAYER)

    /** Well-formed HDR10 is the common case and keeps every field; only the 0.0001 floor is raised into the volume. */
    @Test
    fun wellFormedMetadataSurvives() {
        val plan = planHdrLuminance(metadata(1000, 400, 1000, 0.0001), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(1000L, plan.masteringMax)
        assertEquals(50L, plan.masteringMinScaled)
        assertTrue(plan.sendMaxCll)
        assertEquals(1000L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(400L, plan.maxFall)
    }

    /** The volume cap drops only what is strictly above the curve's maximum, so exactly 10000 survives. */
    @Test
    fun maxCllAtThePqCeilingIsKept() {
        val plan = planHdrLuminance(metadata(10000, 600, 10000, 0.0001), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(10000L, plan.masteringMax)
        assertTrue(plan.sendMaxCll)
        assertEquals(10000L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(600L, plan.maxFall)
    }

    /** MaxCLL above the mastering peak is fatal on version 1; the light level goes, not the mastering range. */
    @Test
    fun maxCllAboveTheMasteringMaxIsDroppedOnVersionOne() {
        val plan = planHdrLuminance(metadata(4000, 400, 1000, 0.005), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(1000L, plan.masteringMax)
        assertFalse(plan.sendMaxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(400L, plan.maxFall)
    }

    @Test
    fun maxCllAboveTheMasteringMaxIsKeptOnVersionTwo() {
        val plan = planHdrLuminance(metadata(4000, 400, 1000, 0.005), support(true, 2))
        assertTrue(plan.sendMastering)
        assertTrue(plan.sendMaxCll)
        assertEquals(4000L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
    }

    /** With MaxCLL unset the pair rule cannot fire, so only the range rule can drop this MaxFALL. */
    @Test
    fun maxFallAboveTheMasteringMaxIsDroppedOnVersionOne() {
        val plan = planHdrLuminance(metadata(0, 1001, 1000, 0.005), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(1000L, plan.masteringMax)
        assertFalse(plan.sendMaxCll)
        assertFalse(plan.sendMaxFall)
    }

    @Test
    fun maxFallAboveMaxCllIsDroppedInEveryVersion() {
        for (version in 1..3) {
            val plan = planHdrLuminance(metadata(600, 900, 1000, 0.0001), support(true, version))
            assertTrue(plan.sendMaxCll)
            assertEquals(600L, plan.maxCll)
            assertFalse(plan.sendMaxFall)
        }
    }

    @Test
    fun maxFallSurvivesWhenMaxCllIsDropped() {
        val plan = planHdrLuminance(metadata(4000, 900, 1000, 0.0001), support(true, 1))
        assertFalse(plan.sendMaxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(900L, plan.maxFall)
    }

    /** Unadvertised mastering would be unsupported_feature; the light levels are then bounded by PQ's ceiling. */
    @Test
    fun masteringIsSuppressedWithoutCompositorSupport() {
        val plan = planHdrLuminance(metadata(4000, 400, 1000, 0.0001), support(false, 1))
        assertFalse(plan.sendMastering)
        assertTrue(plan.sendMaxCll)
        assertEquals(4000L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
    }

    @Test
    fun anInvertedMasteringRangeIsSuppressed() {
        val plan = planHdrLuminance(metadata(500, 100, 1, 5.0), support(true, 1))
        assertFalse(plan.sendMastering)
        assertTrue(plan.sendMaxCll)
        assertTrue(plan.sendMaxFall)
    }

    @Test
    fun anEqualMasteringRangeIsSuppressed() {
        assertFalse(planHdrLuminance(metadata(0, 0, 1, 1.0), support(true, 1)).sendMastering)
    }

    @Test
    fun theMasteringMaxIsCappedAtThePqCeiling() {
        val plan = planHdrLuminance(metadata(0, 0, 4_000_000_000, 0.0001), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(10000L, plan.masteringMax)
    }

    @Test
    fun lightLevelsAboveThePqCeilingAreDroppedInEveryVersion() {
        for (version in 1..3) {
            val plan = planHdrLuminance(metadata(4_000_000_000, 3_000_000_000, 0, 0.0), support(true, version))
            assertFalse(plan.sendMaxCll)
            assertFalse(plan.sendMaxFall)
        }
    }

    @Test
    fun emptyMetadataSendsNothing() {
        val plan = planHdrLuminance(HdrMetadata(), support(true, 1))
        assertFalse(plan.sendMastering)
        assertFalse(plan.sendMaxCll)
        assertFalse(plan.sendMaxFall)
    }

    /** Half a scaled unit rounds up to the smallest floor rather than silently becoming unset; huge values saturate. */
    @Test
    fun theMasteringMinimumScalesRoundingHalfUp() {
        assertEquals(1L, scaleMinLuminance(0.0001))
        assertEquals(1L, scaleMinLuminance(0.00005))
        assertEquals(50L, scaleMinLuminance(0.005))
        assertEquals(10000L, scaleMinLuminance(1.0))
        assertEquals(0L, scaleMinLuminance(0.0))
        assertEquals(0L, scaleMinLuminance(-1.0))
        assertEquals(4294967295L, scaleMinLuminance(1e30))
    }

    @Test
    fun theRangeIsStrictlyAboveMinAndAtMostMax() {
        assertTrue(luminanceInMasteringRange(1, 1, 1000))
        assertTrue(luminanceInMasteringRange(1000, 1, 1000))
        assertFalse(luminanceInMasteringRange(1001, 1, 1000))
        assertFalse(luminanceInMasteringRange(5, 50000, 1000))
        assertTrue(luminanceInMasteringRange(6, 50000, 1000))
        assertFalse(luminanceInMasteringRange(4_000_000_000, 1, 1000))
    }

    @Test
    fun lightLevelsAtOrBelowTheMasteringFloorAreDropped() {
        val plan = planHdrLuminance(metadata(3, 2, 1000, 5.0), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(50000L, plan.masteringMinScaled)
        assertFalse(plan.sendMaxCll)
        assertFalse(plan.sendMaxFall)
    }

    /** 4000 nits with no mastering range is inside PQ's volume but outside HLG's, a fatal error on version 1. */
    @Test
    fun hlgLightLevelsAreBoundedAtAThousandNits() {
        val hlg = planHdrLuminance(metadata(4000, 400, 0, 0.0, SourceTransfer.HLG), support(false, 1))
        assertFalse(hlg.sendMastering)
        assertFalse(hlg.sendMaxCll)
        assertTrue(hlg.sendMaxFall)
        assertEquals(400L, hlg.maxFall)

        val pq = planHdrLuminance(metadata(4000, 400, 0, 0.0, SourceTransfer.PQ), support(false, 1))
        assertTrue(pq.sendMaxCll)
        assertEquals(4000L, pq.maxCll)
    }

    @Test
    fun exactlyAThousandNitsIsInsideHlgsVolume() {
        assertTrue(planHdrLuminance(metadata(1000, 0, 0, 0.0, SourceTransfer.HLG), support(false, 1)).sendMaxCll)
        assertFalse(planHdrLuminance(metadata(1001, 0, 0, 0.0, SourceTransfer.HLG), support(false, 1)).sendMaxCll)
        assertEquals(1000L, primaryVolumeMaxNits(SourceTransfer.HLG))
        assertEquals(10000L, primaryVolumeMaxNits(SourceTransfer.PQ))
    }

    /** Extended volume lets HLG's mastering range reach 4000, yet both versions must still refuse a 2000-nit level. */
    @Test
    fun theVolumeCapHoldsInEveryVersion() {
        val source = metadata(2000, 1500, 4000, 0.01, SourceTransfer.HLG)
        val v1 = planHdrLuminance(source, support(true, 1, extendedTargetVolume = true))
        val v2 = planHdrLuminance(source, support(true, 2, extendedTargetVolume = true))
        assertFalse(v1.sendMaxCll)
        assertFalse(v2.sendMaxCll)
        assertEquals(v1.sendMaxFall, v2.sendMaxFall)
    }

    @Test
    fun hlgMasteringIsClampedWithoutExtendedVolume() {
        val clamped = planHdrLuminance(metadata(0, 0, 4000, 0.005, SourceTransfer.HLG), support(true, 1))
        assertTrue(clamped.sendMastering)
        assertEquals(1000L, clamped.masteringMax)

        val extended = planHdrLuminance(
            metadata(0, 0, 4000, 0.005, SourceTransfer.HLG),
            support(true, 1, extendedTargetVolume = true),
        )
        assertTrue(extended.sendMastering)
        assertEquals(4000L, extended.masteringMax)
    }

    @Test
    fun pqMasteringIsUnaffectedByTheExtendedVolumeGate() {
        val plan = planHdrLuminance(metadata(0, 0, 10000, 0.0001), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(10000L, plan.masteringMax)
    }

    /** After player-side tone mapping the description claims the produced peak, not the source's range. */
    @Test
    fun aTonemappedDescriptionClaimsTheProducedPeak() {
        val source = metadata(10000, 600, 10000, 0.0001)
        val described = describeTonemappedTo(source, 600)
        assertEquals(SourceTransfer.PQ, described.transfer)
        assertEquals(SourcePrimaries.BT2020, described.primaries)
        assertEquals(600L, described.maxCll)
        assertEquals(600L, described.maxLuminance)
        assertEquals(600L, described.maxFall)
        assertEquals(source.minLuminance, described.minLuminance)

        assertEquals(0L, describeTonemappedTo(metadata(10000, 900, 10000, 0.0001), 600).maxFall)
        assertEquals(10000L, describeTonemappedTo(source, 0).maxCll)
        assertEquals(1000L, describeTonemappedTo(metadata(0, 0, 0, 0.005, SourceTransfer.HLG), 4000).maxCll)
    }

    @Test
    fun aTonemappedDescriptionIsSendable() {
        val plan = planHdrLuminance(describeTonemappedTo(metadata(10000, 600, 10000, 0.0001), 600), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(600L, plan.masteringMax)
        assertTrue(plan.sendMaxCll)
        assertEquals(600L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(600L, plan.maxFall)
    }

    /** Containment is two-sided: a floor below 0.005 nits is raised, keeping the compositor's fallback peak. */
    @Test
    fun theMasteringFloorIsClampedIntoThePrimaryVolume() {
        val plan = planHdrLuminance(metadata(0, 0, 1000, 0.0001), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(50L, plan.masteringMinScaled)
        assertEquals(1000L, plan.masteringMax)

        val absent = planHdrLuminance(metadata(0, 0, 1000, 0.0), support(true, 1))
        assertTrue(absent.sendMastering)
        assertEquals(50L, absent.masteringMinScaled)

        val extended = planHdrLuminance(metadata(0, 0, 1000, 0.0001), support(true, 1, extendedTargetVolume = true))
        assertTrue(extended.sendMastering)
        assertEquals(1L, extended.masteringMinScaled)
    }

    @Test
    fun aMasteringFloorInsideTheVolumeIsUntouched() {
        val plan = planHdrLuminance(metadata(0, 0, 1000, 0.05), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(500L, plan.masteringMinScaled)
    }

    @Test
    fun eachGateCanVetoOnItsOwn() {
        val pq = metadata(1000, 400, 1000, 0.0001)
        assertTrue(decideHdr(allGatesPass, pq).describe)
        assertFalse(decideHdr(allGatesPass.copy(allowed = false), pq).describe)
        assertFalse(decideHdr(allGatesPass.copy(clientCanDescribe = false), pq).describe)
        assertFalse(decideHdr(allGatesPass.copy(outputIsHdr = false), pq).describe)
        assertFalse(decideHdr(allGatesPass.copy(sourceDescribable = false), pq).describe)
        assertFalse(decideHdr(allGatesPass, metadata(0, 0, 0, 0.0, SourceTransfer.SDR)).describe)
    }

    @Test
    fun compositorModeLeavesThePeakOnAuto() {
        val decision = decideHdr(allGatesPass.copy(displayPeakNits = 600), metadata(10000, 600, 10000, 0.0001))
        assertTrue(decision.describe)
        assertFalse(decision.toneMapInPlayer)
        assertEquals(0L, decision.targetPeakNits)
    }

    @Test
    fun playerModeAdoptsTheDisplayPeak() {
        val inputs = allGatesPass.copy(requested = HdrToneMapping.PLAYER, displayPeakNits = 600)
        val decision = decideHdr(inputs, metadata(10000, 600, 10000, 0.0001))
        assertTrue(decision.describe)
        assertTrue(decision.toneMapInPlayer)
        assertEquals(600L, decision.targetPeakNits)
    }

    /** Undescribed, the buffer is an SDR signal, so mpv maps to the output's white, not to the HDR-mode peak. */
    @Test
    fun anUndescribedHdrSourceAdoptsTheSdrReference() {
        for (transfer in hdrTransfers) {
            val source = metadata(1000, 400, 1000, 0.0001, transfer)
            val inputs = allGatesPass.copy(outputIsHdr = false, displayPeakNits = 600, sdrReferenceNits = 200)
            val decision = decideHdr(inputs, source)
            assertFalse(decision.describe)
            assertTrue(decision.toneMapInPlayer)
            assertEquals(200L, decision.targetPeakNits)

            val player = decideHdr(inputs.copy(requested = HdrToneMapping.PLAYER), source)
            assertFalse(player.describe)
            assertTrue(player.toneMapInPlayer)
            assertEquals(200L, player.targetPeakNits)
        }
    }

    @Test
    fun anUndescribedSourceWithoutAnSdrReferenceStaysOnAuto() {
        val source = metadata(1000, 400, 1000, 0.0001)
        val inputs = allGatesPass.copy(outputIsHdr = false, displayPeakNits = 600)
        assertEquals(0L, decideHdr(inputs, source).targetPeakNits)
        assertEquals(0L, decideHdr(inputs.copy(sdrReferenceNits = 9), source).targetPeakNits)
        assertEquals(10L, decideHdr(inputs.copy(sdrReferenceNits = 10), source).targetPeakNits)
    }

    /** An ordinary BT.709 file has nothing to map down, so naming a peak would change plain SDR playback. */
    @Test
    fun anUndescribedSdrSourceKeepsThePeakOnAuto() {
        val sdr = metadata(0, 0, 0, 0.0, SourceTransfer.SDR)
        val inputs = allGatesPass.copy(outputIsHdr = false, displayPeakNits = 600, sdrReferenceNits = 200)
        val decision = decideHdr(inputs, sdr)
        assertFalse(decision.describe)
        assertEquals(0L, decision.targetPeakNits)
        val everyGate = playerMode.copy(displayPeakNits = 600, sdrReferenceNits = 200)
        assertEquals(0L, decideHdr(everyGate, sdr).targetPeakNits)
    }

    @Test
    fun describedPlayerModeIgnoresTheSdrReference() {
        val inputs = allGatesPass.copy(requested = HdrToneMapping.PLAYER, displayPeakNits = 600, sdrReferenceNits = 200)
        val decision = decideHdr(inputs, metadata(10000, 600, 10000, 0.0001))
        assertTrue(decision.describe)
        assertTrue(decision.toneMapInPlayer)
        assertEquals(600L, decision.targetPeakNits)
    }

    /** Without a usable peak (mpv's option starts at 10) player mode degrades to passthrough. */
    @Test
    fun playerModeWithoutAPeakFallsBackToPassthrough() {
        val inputs = allGatesPass.copy(requested = HdrToneMapping.PLAYER)
        val absent = decideHdr(inputs, metadata(10000, 600, 10000, 0.0001))
        assertTrue(absent.describe)
        assertFalse(absent.toneMapInPlayer)
        assertEquals(0L, absent.targetPeakNits)
        assertFalse(decideHdr(inputs.copy(displayPeakNits = 5), metadata(10000, 600, 10000, 0.0001)).toneMapInPlayer)
    }

    /** mpv's target and the declared peak are one number: whatever is decided survives the rewrite unchanged. */
    @Test
    fun theDecidedPeakIsTheDescribedPeak() {
        for (peak in listOf(600L, 1000L, 1500L, 4000L, 12000L)) {
            for (transfer in hdrTransfers) {
                val source = metadata(0, 0, 0, 0.0001, transfer)
                val decision = decideHdr(playerMode.copy(displayPeakNits = peak), source)
                assertTrue(decision.toneMapInPlayer)
                assertTrue(decision.targetPeakNits <= primaryVolumeMaxNits(transfer))
                val described = describeTonemappedTo(source, decision.targetPeakNits)
                assertEquals(decision.targetPeakNits, described.maxLuminance)
                assertEquals(decision.targetPeakNits, described.maxCll)
            }
        }
        val clamped = allGatesPass.copy(requested = HdrToneMapping.PLAYER, displayPeakNits = 12000)
        assertEquals(10000L, decideHdr(clamped, metadata(0, 0, 0, 0.0001, SourceTransfer.PQ)).targetPeakNits)
        assertEquals(
            1000L,
            decideHdr(clamped.copy(displayPeakNits = 1500), metadata(0, 0, 0, 0.0001, SourceTransfer.HLG))
                .targetPeakNits,
        )

        val fallback = decideHdr(
            allGatesPass.copy(outputIsHdr = false, sdrReferenceNits = 99999),
            metadata(0, 0, 0, 0.0001, SourceTransfer.PQ),
        )
        assertFalse(fallback.describe)
        assertEquals(10000L, fallback.targetPeakNits)
    }

    @Test
    fun theDecidedPeakIsSendable() {
        for (transfer in hdrTransfers) {
            val source = metadata(4000, 2000, 4000, 0.0001, transfer)
            val decision = decideHdr(playerMode.copy(displayPeakNits = 700), source)
            val plan = planHdrLuminance(describeTonemappedTo(source, decision.targetPeakNits), support(true, 1))
            assertTrue(plan.sendMaxCll)
            assertEquals(decision.targetPeakNits, plan.maxCll)
            assertTrue(plan.sendMastering)
            assertEquals(decision.targetPeakNits, plan.masteringMax)
            assertTrue(!plan.sendMaxFall || plan.maxFall <= plan.maxCll)
        }
    }

    /** Figures a compositor reports: a 400-nit panel over 203-nit white, a default 800 over 200, a raised white. */
    @Test
    fun hdrOutputsAreRecognisedByTheirHeadroom() {
        assertTrue(outputHasHdrHeadroom(400, 203))
        assertTrue(outputHasHdrHeadroom(800, 200))
        assertTrue(outputHasHdrHeadroom(465, 208))
    }

    /** A software-dimmed SDR output keeps reporting its undimmed maximum over a lower white (80% is 161, 70% 137). */
    @Test
    fun sdrOutputsAreRejectedEvenWhenDimmed() {
        assertFalse(outputHasHdrHeadroom(200, 200))
        assertFalse(outputHasHdrHeadroom(200, 161))
        assertFalse(outputHasHdrHeadroom(200, 137))
    }

    @Test
    fun unknownLuminancesAreNoHdr() {
        assertFalse(outputHasHdrHeadroom(0, 0))
        assertFalse(outputHasHdrHeadroom(800, 0))
        assertFalse(outputHasHdrHeadroom(100, 203))
    }

    @Test
    fun theHeadroomMarginIsExactlyOneAndAHalf() {
        assertFalse(outputHasHdrHeadroom(304, 203))
        assertTrue(outputHasHdrHeadroom(305, 203))
        assertTrue(outputHasHdrHeadroom(300, 200))
        assertFalse(outputHasHdrHeadroom(299, 200))
        assertFalse(outputHasHdrHeadroom(1, 1))
        assertFalse(outputHasHdrHeadroom(2, 2))
    }

    @Test
    fun headroomHoldsAtTheTopOfTheRange() {
        assertFalse(outputHasHdrHeadroom(UINT32_MAX, UINT32_MAX))
        assertTrue(outputHasHdrHeadroom(UINT32_MAX, 1))
        assertFalse(outputHasHdrHeadroom(1000, UINT32_MAX))
    }

    /** Naming an unadvertised curve is a fatal invalid_tf, so each curve is pinned to its own support flag. */
    @Test
    fun onlyAdvertisedCurvesAreDescribable() {
        val pqOnly = CompositorColorSupport(bt2020 = true, pq = true, hlg = false)
        val hlgOnly = CompositorColorSupport(bt2020 = true, pq = false, hlg = true)
        val both = CompositorColorSupport(bt2020 = true, pq = true, hlg = true)
        val pq = metadata(1000, 400, 1000, 0.005, SourceTransfer.PQ)
        val hlg = pq.copy(transfer = SourceTransfer.HLG)

        assertTrue(sourceIsDescribable(pq, pqOnly))
        assertFalse(sourceIsDescribable(hlg, pqOnly))
        assertTrue(sourceIsDescribable(hlg, hlgOnly))
        assertFalse(sourceIsDescribable(pq, hlgOnly))
        assertTrue(sourceIsDescribable(pq, both))
        assertTrue(sourceIsDescribable(hlg, both))
    }

    @Test
    fun sdrAndNarrowGamutSourcesAreNotDescribable() {
        val all = CompositorColorSupport(bt2020 = true, pq = true, hlg = true)
        assertFalse(sourceIsDescribable(metadata(0, 0, 0, 0.0, SourceTransfer.SDR), all))
        val narrow = metadata(1000, 400, 1000, 0.005).copy(primaries = SourcePrimaries.OTHER)
        assertFalse(sourceIsDescribable(narrow, all))
        val pq = metadata(1000, 400, 1000, 0.005)
        assertFalse(sourceIsDescribable(pq, CompositorColorSupport(bt2020 = false, pq = true, hlg = true)))
    }

    /** min-luma arrives unsanitised: NaN and -∞ scale to 0 (then the floor), +∞ saturates. */
    @Test
    fun aNonFiniteMasteringMinimumIsRejected() {
        assertEquals(0L, scaleMinLuminance(Double.NaN))
        assertEquals(0L, scaleMinLuminance(Double.NEGATIVE_INFINITY))
        assertEquals(UINT32_MAX, scaleMinLuminance(Double.POSITIVE_INFINITY))

        val plan = planHdrLuminance(metadata(1000, 400, 1000, Double.NaN), support(true, 1))
        assertTrue(plan.sendMastering)
        assertEquals(50L, plan.masteringMinScaled)
        assertEquals(1000L, plan.masteringMax)
    }

    @Test
    fun versionTwoKeepsBothLightLevelsOutsideTheMasteringRange() {
        val plan = planHdrLuminance(metadata(5000, 4000, 1000, 0.005), support(true, 2))
        assertTrue(plan.sendMastering)
        assertEquals(1000L, plan.masteringMax)
        assertTrue(plan.sendMaxCll)
        assertEquals(5000L, plan.maxCll)
        assertTrue(plan.sendMaxFall)
        assertEquals(4000L, plan.maxFall)
    }

    /** The undescribed fallback belongs to any veto, not only an SDR output. */
    @Test
    fun everyVetoStillAdoptsTheSdrReference() {
        val vetoes = listOf(
            allGatesPass.copy(allowed = false),
            allGatesPass.copy(clientCanDescribe = false),
            allGatesPass.copy(sourceDescribable = false),
        )
        for (inputs in vetoes) {
            val decision = decideHdr(inputs.copy(sdrReferenceNits = 203), metadata(1000, 400, 1000, 0.005))
            assertFalse(decision.describe)
            assertEquals(203L, decision.targetPeakNits)
            assertTrue(decision.toneMapInPlayer)
        }
    }

    /** The plane skips an equal snapshot, so a field left out of equality leaves a stale description attached. */
    @Test
    fun metadataEqualityComparesEveryField() {
        val base = metadata(1000, 400, 4000, 0.005)
        assertEquals(metadata(1000, 400, 4000, 0.005), base)
        assertNotEquals(base, base.copy(transfer = SourceTransfer.HLG))
        assertNotEquals(base, base.copy(primaries = SourcePrimaries.OTHER))
        assertNotEquals(base, base.copy(maxCll = 999))
        assertNotEquals(base, base.copy(maxFall = 399))
        assertNotEquals(base, base.copy(maxLuminance = 3999))
        assertNotEquals(base, base.copy(minLuminance = 0.0051))
    }
}
