package com.edde746.plezy.importer

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption

/**
 * The files Plezy's earlier releases left, under test resources `earlier-release/` (written by
 * tools/earlier-release-fixtures/generate.py).
 */
internal object EarlierReleaseFixtures {
    /** Epoch ms the fixtures' timestamps count from. */
    const val T = 1_700_000_000_000

    fun path(name: String): Path = Path.of(checkNotNull(EarlierReleaseFixtures::class.java.getResource("/earlier-release/$name")) { name }.toURI())

    /** The fixture directory [name] copied to a new temporary directory, for tests that change it. */
    fun copyOf(name: String): Path {
        val source = path(name)
        val target = Files.createTempDirectory("flutter-import")
        Files.list(source).use { files -> files.forEach { Files.copy(it, target.resolve(it.fileName), StandardCopyOption.REPLACE_EXISTING) } }
        return target
    }
}
