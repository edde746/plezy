package com.edde746.plezy.mpv.video.hdr

import kotlin.test.Test
import kotlin.test.assertEquals

class VideoParamsTest {
    /** mpv sends the whole map every time, in its own key order, with fields the HDR decision has no use for. */
    @Test
    fun everyFieldPresentIsRead() {
        val metadata = parseSourceHdrMetadata(
            """{"pixelformat":"yuv420p10","w":3840,"gamma":"pq","primaries":"bt.2020","min-luma":0.0001,""" +
                """"max-luma":1000.0,"max-cll":999.0,"max-fall":400.0,"chroma-location":"mpeg2/4/h264"}""",
        )
        assertEquals(SourceHdrMetadata("pq", "bt.2020", 999.0, 400.0, 1000.0, 0.0001), metadata)
    }

    /** The common HDR10 case: a curve and gamut with no static metadata at all; both names still come through. */
    @Test
    fun namesSurviveWithNoLuminances() {
        assertEquals(
            SourceHdrMetadata(transfer = "hlg", primaries = "bt.2020"),
            parseSourceHdrMetadata("""{"gamma":"hlg","primaries":"bt.2020"}"""),
        )
    }

    /** An absent luminance never picks up a neighbour's value or a default. */
    @Test
    fun eachLuminanceIsAbsentOnItsOwn() {
        assertEquals(SourceHdrMetadata(maxCll = 1200.0), parseSourceHdrMetadata("""{"max-cll":1200.0}"""))
        assertEquals(SourceHdrMetadata(maxFall = 250.0), parseSourceHdrMetadata("""{"max-fall":250.0}"""))
        assertEquals(SourceHdrMetadata(minLuminance = 0.005), parseSourceHdrMetadata("""{"min-luma":0.005}"""))
        assertEquals(SourceHdrMetadata(maxLuminance = 4000.0), parseSourceHdrMetadata("""{"max-luma":4000.0}"""))
    }

    /** The mastering floor may be stated as zero; no luminance may be negative. */
    @Test
    fun minLumaAcceptsAZeroAndNoLuminanceANegative() {
        assertEquals(
            SourceHdrMetadata(transfer = "pq"),
            parseSourceHdrMetadata("""{"gamma":"pq","min-luma":0.0,"max-luma":0.0,"max-cll":0.0,"max-fall":0.0}"""),
        )
        assertEquals(
            SourceHdrMetadata(),
            parseSourceHdrMetadata("""{"min-luma":-1.0,"max-luma":-4000.0,"max-cll":-1000.0,"max-fall":-400.0}"""),
        )
    }

    /** What counts as HDR is the caller's judgement, so names pass through verbatim. */
    @Test
    fun unknownNamesPassThroughVerbatim() {
        assertEquals(
            SourceHdrMetadata(transfer = "bt.1886", primaries = "display-p3", maxCll = 120.0),
            parseSourceHdrMetadata("""{"gamma":"bt.1886","primaries":"display-p3","max-cll":120.0}"""),
        )
    }

    /** No stream, another JSON type, or text that is not JSON (a truncated payload) all read as no stream. */
    @Test
    fun anythingButAnObjectYieldsNothing() {
        for (json in listOf(null, "", "null", "\"pq\"", "[{\"gamma\":\"pq\"}]", "{\"gamma\":\"pq\"", "pq")) {
            assertEquals(SourceHdrMetadata(), parseSourceHdrMetadata(json), "for $json")
        }
    }

    /** A mistyped value is skipped without stopping the rest; an integer luminance is a number like any other. */
    @Test
    fun mistypedValuesAreSkippedButIntegersAreNot() {
        assertEquals(
            SourceHdrMetadata(primaries = "bt.2020", maxLuminance = 4000.0),
            parseSourceHdrMetadata(
                """{"gamma":2.2,"primaries":"bt.2020","max-cll":"1000","max-luma":4000,"min-luma":"0.0001"}""",
            ),
        )
        assertEquals(
            SourceHdrMetadata(primaries = "bt.2020"),
            parseSourceHdrMetadata("""{"gamma":null,"primaries":"bt.2020","max-fall":true}"""),
        )
    }

    /** Only mpv's PQ, HLG and BT.2020 names select HDR; anything else is SDR over other primaries. */
    @Test
    fun mpvNamesMapToTheSourceColourSpace() {
        val pq = SourceHdrMetadata(transfer = "pq", primaries = "bt.2020").toHdrMetadata()
        assertEquals(SourceTransfer.PQ, pq.transfer)
        assertEquals(SourcePrimaries.BT2020, pq.primaries)
        assertEquals(SourceTransfer.HLG, SourceHdrMetadata(transfer = "hlg").toHdrMetadata().transfer)
        val sdr = SourceHdrMetadata(transfer = "bt.1886", primaries = "display-p3").toHdrMetadata()
        assertEquals(SourceTransfer.SDR, sdr.transfer)
        assertEquals(SourcePrimaries.OTHER, sdr.primaries)
    }

    /** Whole nits rounded half up; a positive value never rounds to "not stated"; huge values saturate. */
    @Test
    fun luminancesBecomeWholeNits() {
        val metadata =
            SourceHdrMetadata(maxCll = 999.5, maxFall = 0.2, maxLuminance = 1e12, minLuminance = 0.0001).toHdrMetadata()
        assertEquals(1000L, metadata.maxCll)
        assertEquals(1L, metadata.maxFall)
        assertEquals(UINT32_MAX, metadata.maxLuminance)
        assertEquals(0.0001, metadata.minLuminance)
        assertEquals(999L, SourceHdrMetadata(maxCll = 999.4).toHdrMetadata().maxCll)
        assertEquals(0L, SourceHdrMetadata().toHdrMetadata().maxCll)
    }
}
