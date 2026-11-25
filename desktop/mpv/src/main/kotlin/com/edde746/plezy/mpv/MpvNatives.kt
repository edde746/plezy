package com.edde746.plezy.mpv

import java.lang.foreign.Arena
import java.lang.foreign.SymbolLookup
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.isDirectory
import kotlin.io.path.isRegularFile
import kotlin.io.path.name

/**
 * Locates and loads libmpv from the pinned mpv-build artifact, by absolute path: nothing depends on `PATH` or
 * `LD_LIBRARY_PATH`.
 *
 * The directory is the `plezy.mpv.dir` system property, else the `PLEZY_MPV_DIR` environment variable, else `mpv/`
 * in a packaged app's resources (`compose.application.resources.dir`, where app-desktop's `createDistributable` puts
 * it). Gradle's `app-desktop` run task and the remote harness point the property at mpv-jvm's extracted artifact
 * (`build/mpv/<arch>/`); the library is found anywhere below the directory (`libmpv-2.dll` at the root on Windows,
 * `lib/<multiarch>/libmpv.so.2` on Linux).
 *
 * Linux only: mpv-build's libmpv links `liblua5.2.so.0`, `libmujs.so.3` and `libdisplay-info.so.1` under Ubuntu
 * sonames other distributions lack. If `plezy.mpv.preload` names a directory, every shared object in it
 * is loaded first; the dynamic linker then satisfies libmpv's `DT_NEEDED` entries from those already-loaded sonames.
 * The Flatpak needs no preload: it ships the three in `/app/lib`, on the sandbox's library path, with Ubuntu's
 * `libbz2.so.1.0` (the freedesktop runtime names it `libbz2.so.1`).
 *
 * The jextract bindings ([com.edde746.plezy.mpv.ffi.MpvFfi]) resolve every symbol through [lookup].
 */
object MpvNatives {
    const val DIR_PROPERTY = "plezy.mpv.dir"
    const val DIR_ENV = "PLEZY_MPV_DIR"
    const val PRELOAD_PROPERTY = "plezy.mpv.preload"
    private const val RESOURCES_PROPERTY = "compose.application.resources.dir"

    private val isWindows = System.getProperty("os.name").startsWith("Windows")
    private val libraryName = if (isWindows) "libmpv-2.dll" else "libmpv.so.2"

    /** The libmpv file that is (or will be) loaded; throws with a setup hint when it cannot be found. */
    val library: Path by lazy { find() }

    private val symbols: SymbolLookup by lazy {
        if (!isWindows) System.getProperty(PRELOAD_PROPERTY)?.let(Path::of)?.let(::preload)
        SymbolLookup.libraryLookup(library, Arena.global())
    }

    /** Called from the generated `MpvFfi` class initializer. */
    @JvmStatic
    fun lookup(): SymbolLookup = symbols

    private fun find(): Path {
        val configured = System.getProperty(DIR_PROPERTY) ?: System.getenv(DIR_ENV)
            ?: System.getProperty(RESOURCES_PROPERTY)?.let { Path.of(it, "mpv").toString() }
            ?: error("libmpv location not configured: set -D$DIR_PROPERTY=<dir> (or $DIR_ENV) to the extracted mpv-build artifact")
        val dir = Path.of(configured).toAbsolutePath()
        require(dir.isDirectory()) { "$DIR_PROPERTY=$dir is not a directory" }
        val hits = Files.walk(dir, 4).use { paths -> paths.filter { it.name == libraryName }.sorted().toList() }
        return hits.firstOrNull() ?: error("$libraryName not found under $dir")
    }

    private fun preload(dir: Path) {
        require(dir.isDirectory()) { "$PRELOAD_PROPERTY=$dir is not a directory" }
        Files.list(dir).use { paths ->
            paths.filter { it.isRegularFile() && it.name.contains(".so") }.sorted().forEach { SymbolLookup.libraryLookup(it, Arena.global()) }
        }
    }
}
