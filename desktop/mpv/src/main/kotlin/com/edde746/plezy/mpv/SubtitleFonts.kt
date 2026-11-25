package com.edde746.plezy.mpv

import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The subtitle fonts the app ships (resources under `subtitle-fonts/`): Go Noto Current, every living script but
 * Hangul, CJK ideographs included, and its Hangul companion under the same family name ([FAMILY]). libass reads fonts
 * from a directory only, so they are written out once per process to the system's temporary directory: a file of the
 * wrong length is written again, through a `.partial` file and a rename, and files that aren't the fonts go. mpv gets
 * the directory as `sub-fonts-dir` and the family as `sub-font`; a failure is a warning, and subtitles fall back to the
 * system's fonts.
 */
internal object SubtitleFonts {
    const val FAMILY = "Go Noto Current-Regular"

    private val FILES = listOf("go-noto-current-regular.ttf", "go-noto-kurrent-hangul.ttf")
    private val log = System.getLogger(SubtitleFonts::class.java.name)

    /** The fonts' directory, or null when they couldn't be written. */
    val directory: Path? by lazy {
        try {
            write(Path.of(System.getProperty("java.io.tmpdir"), "plezy-subtitle-fonts"))
        } catch (e: IOException) {
            log.log(System.Logger.Level.WARNING, "subtitle fonts not set up: subtitles use the system's fonts", e)
            null
        }
    }

    /** mpv's options for the fonts: `sub-fonts-dir` and `sub-font`; none without them. */
    fun options(): Map<String, String> =
        directory?.let { mapOf("sub-fonts-dir" to it.toString(), "sub-font" to FAMILY) }.orEmpty()

    /** Writes the fonts into [dir], keeping those already there at their length, and returns it. */
    internal fun write(dir: Path): Path {
        Files.createDirectories(dir)
        Files.list(dir).use { files -> files.filter { it.fileName.toString() !in FILES }.forEach(Files::delete) }
        for (name in FILES) {
            val resource = SubtitleFonts::class.java.getResource("/subtitle-fonts/$name") ?: throw IOException("the app has no $name")
            val length = resource.openConnection().contentLengthLong
            val target = dir.resolve(name)
            if (Files.exists(target) && Files.size(target) == length) continue
            val partial = dir.resolve("$name.partial")
            resource.openStream().use { Files.copy(it, partial, StandardCopyOption.REPLACE_EXISTING) }
            Files.move(partial, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        }
        return dir
    }
}
