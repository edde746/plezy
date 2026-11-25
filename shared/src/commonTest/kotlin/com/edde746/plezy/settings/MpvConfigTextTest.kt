package com.edde746.plezy.settings

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class MpvConfigTextTest {
    @Test
    fun parsesPlainKeyValueLines() = assertEquals(mapOf("hwdec" to "auto", "volume" to "100"), parseMpvConfigText("hwdec=auto\nvolume=100"))

    @Test
    fun trimsWhitespaceAroundKeyAndValue() = assertEquals(mapOf("hwdec" to "auto"), parseMpvConfigText("  hwdec   =   auto  "))

    @Test
    fun skipsBlankLines() = assertEquals(mapOf("hwdec" to "auto"), parseMpvConfigText("\n\nhwdec=auto\n\n"))

    @Test
    fun skipsCommentLinesEvenIndented() =
        assertEquals(mapOf("hwdec" to "auto"), parseMpvConfigText("# this is a comment\n  # indented comment\nhwdec=auto"))

    @Test
    fun skipsLinesWithoutAnEqualsSign() = assertEquals(mapOf("foo" to "bar"), parseMpvConfigText("justakey\nfoo=bar"))

    @Test
    fun skipsLinesWithAnEmptyKey() = assertEquals(mapOf("foo" to "bar"), parseMpvConfigText("=value\nfoo=bar"))

    @Test
    fun splitsOnTheFirstEqualsSignOnly() = assertEquals(mapOf("params" to "a=1,b=2"), parseMpvConfigText("params=a=1,b=2"))

    @Test
    fun allowsAnEmptyValue() = assertEquals(mapOf("flag" to ""), parseMpvConfigText("flag="))

    @Test
    fun aLaterDuplicateKeyOverridesTheEarlier() = assertEquals(mapOf("k" to "2"), parseMpvConfigText("k=1\nk=2"))

    @Test
    fun emptyInputYieldsNothing() = assertTrue(parseMpvConfigText("").isEmpty())

    @Test
    fun stripsOnePairOfMatchingSingleQuotes() =
        assertEquals(mapOf("sub-font" to "NetflixSans-Bold"), parseMpvConfigText("sub-font = 'NetflixSans-Bold'"))

    @Test
    fun stripsOnePairOfMatchingDoubleQuotes() =
        assertEquals(mapOf("sub-font" to "Netflix Sans"), parseMpvConfigText("sub-font = \"Netflix Sans\""))

    @Test
    fun stripsQuotesFromNumericValues() =
        assertEquals(mapOf("sub-pos" to "85", "sub-blur" to "0.2"), parseMpvConfigText("sub-pos = '85'\nsub-blur = '0.2'"))

    @Test
    fun keepsAnUnmatchedLeadingQuote() = assertEquals(mapOf("k" to "'abc"), parseMpvConfigText("k='abc"))

    @Test
    fun keepsMismatchedQuoteKinds() = assertEquals(mapOf("k" to "'abc\""), parseMpvConfigText("k='abc\""))

    @Test
    fun keepsInteriorQuotes() = assertEquals(mapOf("k" to "it's"), parseMpvConfigText("k=it's"))

    @Test
    fun anEmptyQuotedValueIsEmpty() = assertEquals(mapOf("flag" to ""), parseMpvConfigText("flag=''"))

    @Test
    fun stripsOnlyTheOuterQuotePair() = assertEquals(mapOf("k" to "'a'"), parseMpvConfigText("k=\"'a'\""))
}
