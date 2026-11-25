package com.edde746.plezy.strings

import kotlin.test.Test
import kotlin.test.assertEquals

class LocaleLookupTest {
    private val tags = arrayOf("en", "de", "pt", "pt-BR", "pt-PT", "zh", "zh-Hant")

    private fun chain(tag: String) = lookupChain(tag, tags).map { tags[it] }

    @Test
    fun regionFallsBackToLanguage() {
        assertEquals(listOf("pt-BR", "pt"), chain("pt-BR"))
        assertEquals(listOf("pt-PT", "pt"), chain("pt-PT"))
        assertEquals(listOf("de"), chain("de-AT"))
    }

    @Test
    fun regionalFileServesTheWholeLanguage() {
        val regional = arrayOf("en", "pt-BR", "de")
        assertEquals(listOf("pt-BR"), lookupChain("pt", regional).map { regional[it] })
        assertEquals(listOf("pt-BR"), lookupChain("pt-PT", regional).map { regional[it] })
        assertEquals(listOf("pt-BR"), lookupChain("pt-BR", regional).map { regional[it] })
        assertEquals(emptyList(), lookupChain("p", regional).toList())
    }

    @Test
    fun separatorsAndCaseDoNotMatter() {
        assertEquals(listOf("pt-BR", "pt"), chain("pt_br"))
        assertEquals(listOf("pt-BR", "pt"), chain("PT-br"))
        assertEquals(listOf("de"), chain(" DE "))
    }

    @Test
    fun extensionsAndPrivateUseAreTruncatedWithTheirSingleton() {
        assertEquals(listOf("de"), chain("de-CH-u-co-phonebk"))
        assertEquals(listOf("de"), chain("de-x-formal"))
        assertEquals(emptyList(), chain("x-klingon"))
    }

    @Test
    fun englishAndUnknownLanguagesHaveNoChain() {
        assertEquals(emptyList(), chain("en"))
        assertEquals(emptyList(), chain("en-GB"))
        assertEquals(emptyList(), chain("fi"))
        assertEquals(emptyList(), chain(""))
    }

    @Test
    fun chineseScriptFromRegionAndNoSimplifiedFallbackForTraditional() {
        assertEquals(listOf("zh-Hant"), chain("zh-TW"))
        assertEquals(listOf("zh-Hant"), chain("zh_HK"))
        assertEquals(listOf("zh-Hant"), chain("zh-MO"))
        assertEquals(listOf("zh-Hant"), chain("zh-Hant-SG"))
        assertEquals(listOf("zh"), chain("zh-CN"))
        assertEquals(listOf("zh"), chain("zh-Hans-TW"))
        assertEquals(listOf("zh"), chain("zh"))
        assertEquals(emptyList(), lookupChain("zh-TW", arrayOf("en", "zh")).toList())
    }

    @Test
    fun europeanPortugueseRegionsUseThePortugalFileAndOthersFallBackToPortuguese() {
        for (region in listOf("ao", "MZ", "cv", "GW", "st", "TL", "mo", "GQ", "lu", "CH")) {
            assertEquals(listOf("pt-PT", "pt"), chain("pt-$region"), region)
        }
        assertEquals(listOf("pt-PT", "pt"), chain("pt_AO"))
        assertEquals(listOf("pt"), chain("pt"))
        assertEquals(listOf("pt"), chain("pt-US"))
    }
}
