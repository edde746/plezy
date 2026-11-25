package com.edde746.plezy

import kotlin.test.Test
import kotlin.test.assertEquals

/** Which apps that take a web link count as no browser. */
class TvStubTest {
    @Test
    fun androidTvsFrameworkStubsAreNoBrowserWhateverTheirVendor() {
        val handlers = listOf(
            "com.android.tv.frameworkpackagestubs",
            "com.google.android.tv.frameworkpackagestubs",
            "com.amazon.cloud9",
            "com.android.chrome",
            "org.mozilla.firefox",
        )
        assertEquals(listOf(true, true, false, false, false), handlers.map(::isTvStub))
    }
}
