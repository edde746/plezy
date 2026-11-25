package com.edde746.plezy.downloads

import kotlin.test.Test
import kotlin.test.assertEquals

class DownloadNamesTest {
    @Test
    fun aTaskIdBecomesOneSafePathComponent() {
        assertEquals("1234567890", DownloadNames.clean("1234567890"))
        assertEquals("a -b", DownloadNames.clean("a:b"))
        assertEquals("ab", DownloadNames.clean("a/b"))
        assertEquals("_CON", DownloadNames.clean("CON"))
        assertEquals(80, DownloadNames.clean("x".repeat(200)).length)
    }
}
