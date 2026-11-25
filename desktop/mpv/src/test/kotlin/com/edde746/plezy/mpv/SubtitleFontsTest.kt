package com.edde746.plezy.mpv

import java.nio.file.Files
import kotlin.test.Test
import kotlin.test.assertEquals

class SubtitleFontsTest {
    @Test
    fun theFontsAreWrittenAtTheirLengthAndNothingElseStays() {
        val dir = Files.createTempDirectory("fonts")
        Files.writeString(dir.resolve("go-noto-kurrent-hangul.ttf"), "cut short")
        Files.writeString(dir.resolve("old.ttf"), "stale")
        Files.writeString(dir.resolve("go-noto-current-regular.ttf.partial"), "a write that died")

        SubtitleFonts.write(dir)

        val names = Files.list(dir).use { files -> files.map { it.fileName.toString() }.sorted().toList() }
        assertEquals(listOf("go-noto-current-regular.ttf", "go-noto-kurrent-hangul.ttf"), names)
        for (name in names) {
            val bundled = SubtitleFonts::class.java.getResource("/subtitle-fonts/$name")!!.openConnection().contentLengthLong
            assertEquals(bundled, Files.size(dir.resolve(name)), name)
        }
    }
}
