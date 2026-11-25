package com.edde746.plezy.jellyfin

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject

/**
 * HDR and Dolby Vision classification of a MediaBrowser video stream. The two HDR10 fixtures are the same
 * file as Jellyfin 10.11 and Emby 4.9.5 describe it: Emby sends no `VideoRangeType`, so detection must not need it.
 */
class JellyfinDisplayMetadataTest {
    private fun obj(json: String): JsonObject = Json.parseToJsonElement(json).jsonObject
    private val noSource = JsonObject(emptyMap())

    private val embyHdr10 = obj(
        """{"Type":"Video","Codec":"hevc","Profile":"Main 10","BitDepth":10,"VideoRange":"HDR 10","ColorTransfer":"smpte2084",
           "ColorPrimaries":"bt2020","ColorSpace":"bt2020nc","ExtendedVideoType":"Hdr10","Width":640,"Height":360,"AverageFrameRate":24}""",
    )
    private val jellyfinHdr10 = obj(
        """{"Type":"Video","Codec":"hevc","Profile":"Main 10","BitDepth":10,"VideoRange":"HDR","VideoRangeType":"HDR10",
           "ColorTransfer":"smpte2084","ColorPrimaries":"bt2020","ColorSpace":"bt2020nc","Width":640,"Height":360,"AverageFrameRate":24}""",
    )
    private val sdr = obj("""{"Type":"Video","Codec":"h264","VideoRange":"SDR","Width":640,"Height":360,"AverageFrameRate":24}""")

    @Test fun embyHdr10IsDetectedWithoutVideoRangeType() {
        assertFalse("VideoRangeType" in embyHdr10)
        assertTrue(jellyfinIsHdr(noSource, embyHdr10))
        val criteria = jellyfinDisplayCriteria(noSource, embyHdr10)
        assertNotNull(criteria)
        assertTrue(criteria.isHdr)
        assertEquals("smpte2084", criteria.transfer)
        assertEquals("bt2020", criteria.primaries)
    }

    @Test fun jellyfinHdr10IsDetectedFromItsOwnFields() {
        assertTrue(jellyfinIsHdr(noSource, jellyfinHdr10))
        assertTrue(jellyfinDisplayCriteria(noSource, jellyfinHdr10)!!.isHdr)
    }

    @Test fun sdrIsNotHdrOnEitherDialect() {
        assertFalse(jellyfinIsHdr(noSource, sdr))
        assertFalse(jellyfinIsHdr(noSource, JsonObject(sdr + ("VideoRangeType" to kotlinx.serialization.json.JsonPrimitive("SDR")))))
    }

    @Test fun dolbyVisionIsDetectedFromSharedDvFields() {
        val dovi = obj("""{"Type":"Video","Codec":"hevc","VideoRange":"HDR","DvProfile":8,"DvBlSignalCompatibilityId":1,"DvVersionMajor":1,"Width":3840,"Height":2160}""")
        assertTrue(jellyfinIsDolbyVision(dovi))
        assertEquals(8, jellyfinDisplayCriteria(noSource, JsonObject(dovi + ("RealFrameRate" to kotlinx.serialization.json.JsonPrimitive(24))))?.doviProfile)
        assertTrue(jellyfinIsHdr(noSource, dovi))
    }

    @Test fun streamWithoutRangeSignalIsSdr() {
        val bare = obj("""{"Type":"Video","Codec":"h264","Width":1920,"Height":1080}""")
        assertFalse(jellyfinIsHdr(noSource, bare))
        assertFalse(jellyfinIsDolbyVision(bare))
    }
}
