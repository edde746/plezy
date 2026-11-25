package com.edde746.plezy.desktop.linux

import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.nio.file.attribute.PosixFilePermissions
import kotlin.io.path.deleteIfExists
import kotlin.io.path.listDirectoryEntries

/**
 * The artwork MPRIS shows, as a private file: an artwork URL carries the server's token, and every client on the bus
 * (and anything logging its traffic) would read it in `mpris:artUrl`. The bytes are fetched in-process and written
 * here, under [directory] (owner-only, 0700, each file 0600), one file at a time: [write] replaces the last one, [clear]
 * takes it away. Not thread-safe: one thread uses it (the mpris thread).
 */
internal class MprisArtwork(private val directory: Path, private val clock: () -> Long = System::currentTimeMillis) {
    private var current: Path? = null

    /** Writes [bytes] as the artwork now, removing the previous file; the `file://` URI for `mpris:artUrl`. */
    fun write(bytes: ByteArray): String {
        if (!Files.isDirectory(directory)) Files.createDirectories(directory, PosixFilePermissions.asFileAttribute(OWNER_ONLY_DIRECTORY))
        // A directory left by an earlier run or made by something else: owner-only either way.
        Files.setPosixFilePermissions(directory, OWNER_ONLY_DIRECTORY)
        var file = directory.resolve("artwork_${clock()}.jpg")
        var n = 0
        while (Files.exists(file)) file = directory.resolve("artwork_${clock()}_${++n}.jpg")
        Files.createFile(file, PosixFilePermissions.asFileAttribute(OWNER_ONLY_FILE))
        Files.write(file, bytes)
        current?.deleteIfExists()
        current = file
        return file.toUri().toString()
    }

    /** No artwork: the file goes, and the directory once empty. */
    fun clear() {
        current?.deleteIfExists()
        current = null
        if (Files.isDirectory(directory) && directory.listDirectoryEntries().isEmpty()) directory.deleteIfExists()
    }

    companion object {
        private val OWNER_ONLY_DIRECTORY = PosixFilePermissions.fromString("rwx------")
        private val OWNER_ONLY_FILE = PosixFilePermissions.fromString("rw-------")

        /**
         * `$XDG_RUNTIME_DIR/<app>_artwork` (memory-backed, the user's alone, gone at logout), else under the system's
         * temporary directory. In the Flatpak, under `$XDG_RUNTIME_DIR/app/<app id>`, the part of the sandbox's runtime
         * directory the desktop outside it sees at the same path.
         */
        fun directory(env: Map<String, String>, appId: String): Path {
            val runtime = env["XDG_RUNTIME_DIR"]?.takeIf { it.isNotBlank() }
            val base = when {
                runtime == null -> Paths.get(System.getProperty("java.io.tmpdir"))
                env["FLATPAK_ID"].isNullOrBlank() -> Paths.get(runtime)
                else -> Paths.get(runtime, "app", env.getValue("FLATPAK_ID"))
            }
            return base.resolve("${appId}_artwork")
        }
    }
}
