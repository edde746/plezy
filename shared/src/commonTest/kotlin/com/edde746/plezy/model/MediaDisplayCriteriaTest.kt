package com.edde746.plezy.model

import kotlin.test.Test
import kotlin.test.assertEquals

class MediaDisplayCriteriaTest {
    private class ColorCase(
        val name: String,
        val expected: MediaDisplayColorType,
        val isDolbyVision: Boolean = false,
        val doviCompatibilityId: Int? = null,
        val range: String? = null,
        val transfer: String? = null,
        val primaries: String? = null,
        val matrix: String? = null,
        val assumeSdr: Boolean = false,
    )

    private val cases = listOf(
        ColorCase("Dolby Vision", MediaDisplayColorType.DOLBY_VISION, isDolbyVision = true),
        ColorCase("Dolby Vision ignores incidental SDR tags", MediaDisplayColorType.DOLBY_VISION, isDolbyVision = true, primaries = "bt709"),
        ColorCase("HLG compatibility ID", MediaDisplayColorType.HLG, doviCompatibilityId = 4),
        ColorCase("HLG range", MediaDisplayColorType.HLG, range = "HLG"),
        ColorCase("ARIB transfer", MediaDisplayColorType.HLG, transfer = "ARIB-STD-B67"),
        ColorCase("HDR10 compatibility ID", MediaDisplayColorType.PQ, doviCompatibilityId = 1),
        ColorCase("PQ compatibility ID", MediaDisplayColorType.PQ, doviCompatibilityId = 6),
        ColorCase("HDR10 range", MediaDisplayColorType.PQ, range = "DOVIWithHDR10Plus"),
        ColorCase("PQ transfer", MediaDisplayColorType.PQ, transfer = "PQ"),
        ColorCase("SMPTE 2084 transfer", MediaDisplayColorType.PQ, transfer = "smpte2084"),
        ColorCase("ST 2084 transfer", MediaDisplayColorType.PQ, transfer = "ST-2084"),
        ColorCase("BT.2020 primaries", MediaDisplayColorType.PQ, primaries = "BT.2020"),
        ColorCase("BT.2020 matrix", MediaDisplayColorType.PQ, matrix = "bt2020nc"),
        ColorCase("SDR compatibility ID", MediaDisplayColorType.SDR, doviCompatibilityId = 2),
        ColorCase("SDR range", MediaDisplayColorType.SDR, range = "SDR"),
        ColorCase("BT.709 primaries", MediaDisplayColorType.SDR, primaries = "BT.709"),
        ColorCase("assumed SDR", MediaDisplayColorType.SDR, assumeSdr = true),
        ColorCase("missing metadata", MediaDisplayColorType.UNKNOWN),
        ColorCase("unrecognized metadata", MediaDisplayColorType.UNKNOWN, transfer = "gamma22"),
        ColorCase(
            "HLG takes precedence over PQ and SDR",
            MediaDisplayColorType.HLG,
            doviCompatibilityId = 2,
            transfer = "arib-std-b67",
            primaries = "bt2020",
        ),
        ColorCase(
            "PQ takes precedence over SDR and Dolby Vision",
            MediaDisplayColorType.PQ,
            isDolbyVision = true,
            doviCompatibilityId = 2,
            transfer = "smpte2084",
        ),
        ColorCase("SDR takes precedence over Dolby Vision", MediaDisplayColorType.SDR, isDolbyVision = true, doviCompatibilityId = 2),
    )

    @Test
    fun classifiesEveryCase() {
        for (c in cases) {
            val actual = classifyMediaDisplayColor(
                isDolbyVision = c.isDolbyVision,
                doviCompatibilityId = c.doviCompatibilityId,
                range = c.range,
                transfer = c.transfer,
                primaries = c.primaries,
                matrix = c.matrix,
                assumeSdr = c.assumeSdr,
            )
            assertEquals(c.expected, actual, c.name)
        }
    }

    @Test
    fun providesDefaultsAndHdrStateForEveryClassification() {
        val expected = mapOf(
            MediaDisplayColorType.DOLBY_VISION to (true to MediaDisplayColorTags(null, null, null)),
            MediaDisplayColorType.HLG to (true to MediaDisplayColorTags("arib-std-b67", "bt2020", "bt2020nc")),
            MediaDisplayColorType.PQ to (true to MediaDisplayColorTags("smpte2084", "bt2020", "bt2020nc")),
            MediaDisplayColorType.SDR to (false to MediaDisplayColorTags("bt709", "bt709", "bt709")),
            MediaDisplayColorType.UNKNOWN to (false to MediaDisplayColorTags(null, null, null)),
        )
        assertEquals(MediaDisplayColorType.entries.toSet(), expected.keys)
        for ((type, value) in expected) {
            assertEquals(value.first, type.isHdr, type.name)
            assertEquals(value.second, type.defaultTags, type.name)
        }
    }
}
