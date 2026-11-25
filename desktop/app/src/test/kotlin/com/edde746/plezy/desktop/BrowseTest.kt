package com.edde746.plezy.desktop

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse

class BrowseTest {
    @Test
    fun aConfiguredAddonOpensWithItsBarsEncoded() {
        val configure = "https://addon.example/sources=a,b|qualityfilter=480p|key=KEY/configure"
        assertEquals(
            "https://addon.example/sources=a,b%7Cqualityfilter=480p%7Ckey=KEY/configure",
            browserUri(configure).toString(),
        )
    }

    @Test
    fun everyCharacterTheUriParserRejectsIsEncodedAndEscapesAreKept() {
        assertEquals(
            "https://[::1]:8080/a%5Eb%7Bc%7D%60d%5Ce%22f%3Cg%3Eh%20i%5Bj%5D?q=%25zz%E2%82%AC#frag%23ment",
            browserUri("https://[::1]:8080/a^b{c}`d\\e\"f<g>h i[j]?q=%zz%E2%82%AC#frag#ment").toString(),
        )
        assertEquals("https://example.com/caf%C3%A9/%F0%9F%90%A2", browserUri("https://example.com/café/🐢").toString())
    }

    @Test
    fun onlyWebLinksAreOpened() {
        assertFalse(browse("file://127.0.0.1/plezy-link-test/setup.exe"))
        assertFalse(browse("\\\\127.0.0.1\\plezy-link-test\\setup.exe"))
        assertFalse(browse("search-ms:query=plezy-link-test"))
    }
}
