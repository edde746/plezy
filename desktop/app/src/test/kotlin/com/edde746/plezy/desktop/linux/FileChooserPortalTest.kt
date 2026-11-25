package com.edde746.plezy.desktop.linux

import org.freedesktop.dbus.types.UInt32
import org.freedesktop.dbus.types.Variant
import java.io.File
import java.io.IOException
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertNull

class FileChooserPortalTest {
    private fun answer(code: Any?, vararg uris: String): Array<Any?> = arrayOf(code, mapOf("uris" to Variant(uris.toList(), "as")))

    @Test
    fun theChosenFileAndACancelComeBackAsTheyAre() {
        assertEquals(File("/home/user/Documents/plezy export.json"), FileChooserPortal.chosen(answer(UInt32(0), "file:///home/user/Documents/plezy%20export.json")))
        assertNull(FileChooserPortal.chosen(answer(UInt32(1))))
    }

    @Test
    fun anAnswerTheApiDoesntDescribeFailsLikeAnyPortalFailure() {
        // Export and import report a failure only for an IOException; anything else used to end the dialog's thread
        // with no answer at all.
        val malformed = listOf(
            arrayOf<Any?>(),
            arrayOf<Any?>(0, mapOf<String, Variant<*>>()),
            arrayOf<Any?>(UInt32(0)),
            arrayOf<Any?>(UInt32(0), "uris"),
            answer(UInt32(0), "file:///home/user/50%.json"),
            answer(UInt32(0), "file://nas/home/user/export.json"),
            answer(UInt32(0), "https://example.com/export.json"),
            answer(UInt32(2)),
        )
        for (response in malformed) assertFailsWith<IOException>(response.contentToString()) { FileChooserPortal.chosen(response) }
    }
}
