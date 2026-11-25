package com.edde746.plezy.desktop

import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.crash.NativeCrash
import com.edde746.plezy.log.Log
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import kotlin.io.path.isDirectory
import kotlin.io.path.listDirectoryEntries
import kotlin.io.path.name
import kotlin.time.Duration

/**
 * Native crashes (libmpv's, the JVM's own) reported on the next start, as the in-process handler of the earlier
 * releases' crash reporter did. A fatal error in native code ends the JVM before any Java code runs, but HotSpot's own
 * handler writes its report first, in the process: `hs_err_pid<pid>.log` (the signal, the frame it hit, the native
 * stack), in the process's working directory, or in the system's temporary directory where it can't write there.
 *
 * On the next start [collect] moves this app's reports from those places into the crash database, `sentry-native` in
 * the app's data directory; [report] sends each one there as a fatal native event once crash reports are on, its frames
 * at their addresses in the libraries the report lists, which the tracker symbolicates with the libraries' uploaded
 * debug files, as the earlier releases' in-process handler's events were. It deletes each report, sent or not: with
 * crash reports off it goes unsent, as a crash with the reporter off did before.
 */
internal object NativeCrashes {
    /** The crash database's folder in the app's data directory. */
    const val DATABASE = "sentry-native"

    private const val TAG = "NativeCrashes"
    private val REPORT_NAME = Regex("""hs_err_pid\d+\.log""")

    /** The main classes of this app's launches (the product's, the test harness's), as a report's command names them. */
    private const val APP_PACKAGE = "com.edde746.plezy.desktop."

    /** Moves the HotSpot reports of this app's crashes in [places] into [database]; other programs' stay. */
    fun collect(places: List<Path>, database: Path) {
        for (place in places.distinct().filter { it.isDirectory() }) {
            val reports = place.listDirectoryEntries().filter { REPORT_NAME.matches(it.name) }
            for (file in reports) {
                try {
                    if (!ownCrash(Files.readString(file))) continue
                    Files.createDirectories(database)
                    Files.move(file, database.resolve(file.name), StandardCopyOption.REPLACE_EXISTING)
                } catch (e: IOException) {
                    // Another user's report in a shared temporary directory, or one being written.
                    Log.w(TAG, e) { "Can't take the crash report ${file.name}" }
                }
            }
        }
    }

    /**
     * Sends each report in [database] once the crash reporter runs ([CrashCapture.awaitSink], waiting up to [wait]),
     * and deletes it; without a reporter by then (crash reports off) deletes them unsent.
     */
    suspend fun report(database: Path, wait: Duration) {
        if (!database.isDirectory()) return
        val reports = database.listDirectoryEntries().filter { REPORT_NAME.matches(it.name) }
        if (reports.isEmpty()) return
        val sink = CrashCapture.awaitSink(wait)
        for (file in reports) {
            val report = parse(Files.readString(file))
            if (report == null) {
                Log.w(TAG) { "${file.name} isn't a fatal error report: deleted" }
            } else if (sink == null) {
                Log.i(TAG) { "Crash reports are off: the native crash in ${file.name} goes unsent" }
            } else {
                sink.capture(report)
            }
            Files.delete(file)
        }
    }

    /** Whether the HotSpot report [text] is of this app's process: its command names one of the app's main classes. */
    fun ownCrash(text: String): Boolean =
        text.lineSequence().any { it.startsWith("java_command:") && APP_PACKAGE in it }

    /**
     * The HotSpot report [text] as a fatal crash report: what happened (`SIGSEGV (0xb)`, `EXCEPTION_ACCESS_VIOLATION
     * (0xc0000005)`, or an `abort()` [NativeAborts] made a fault), the frame it happened in (for an abort, the first
     * frame outside the C runtime: its caller), its module (`libmpv-2.dll`) as a tag, and the crashed thread's native
     * stack ([NativeCrash]): each frame's address from its library's load address in the report's library list, and
     * those libraries with the ids [identify] reads from their files, which the tracker finds their debug files by.
     * Grouped by the frame. Null for text that isn't a fatal error report.
     */
    fun parse(text: String, identify: (Path) -> NativeImages.Ids? = NativeImages::read): CrashReport? {
        val lines = text.lines()
        val header = lines.indexOfFirst { it.startsWith("# A fatal error has been detected") }
        if (header < 0) return null
        val fault = lines.drop(header + 1).map { it.removePrefix("#").trim() }.firstOrNull { it.isNotEmpty() }
            ?.substringBefore(" at pc=") ?: return null
        val problematic = lines.indexOfFirst { it.startsWith("# Problematic frame:") }.takeIf { it >= 0 }
            ?.let { lines.getOrNull(it + 1)?.removePrefix("#")?.trim() }
            ?.let(::frameText)
        val aborted = aborted(lines, problematic?.let(::moduleOf))
        // An abort's first frame is the handler that faulted (strlen): the stack is the abort's.
        val nativeFrames = section(lines, "Native frames:").drop(if (aborted) 1 else 0).take(MAX_FRAMES)
        val error = if (aborted) "abort()" else fault
        val frame = if (aborted) {
            nativeFrames.map(::frameText).firstOrNull { line -> moduleOf(line)?.let { it !in C_RUNTIMES } == true }
        } else {
            problematic
        }
        val module = frame?.let(::moduleOf)
        val libraries = libraries(section(lines, "Dynamic libraries:"))
        val used = mutableMapOf<Library, NativeCrash.Image>()
        val frames = nativeFrames.map { line ->
            val match = FRAME.find(line) ?: return@map NativeCrash.Frame(null, null, line.substringBefore(NO_SOURCE).trim())
            val (name, offset, symbol) = match.destructured
            val library = libraries.firstOrNull { it.loadedAs(name) }
            library?.let { used.getOrPut(it) { image(it, identify) } }
            NativeCrash.Frame(
                instructionAddress = library?.let { it.base + offset.toLong(16) },
                module = library?.path ?: name,
                function = symbol.trim().takeUnless { it.isEmpty() || it.startsWith(NO_SOURCE) },
            )
        }
        return CrashReport(
            message = if (frame != null) "Native crash: $error in $frame" else "Native crash: $error",
            level = CrashReport.Level.FATAL,
            tags = buildMap {
                put("crash.kind", if (aborted) "abort" else "native")
                module?.let { put("crash.module", it) }
            },
            contexts = mapOf(
                "native_crash" to buildMap {
                    put("error", error)
                    frame?.let { put("frame", it) }
                },
            ),
            fingerprint = listOf(if (aborted) "native-abort" else "native-crash", frame ?: error),
            nativeCrash = NativeCrash(
                type = if (aborted) "SIGABRT" else fault.substringBefore(' '),
                value = if (frame != null) "$error in $frame" else error,
                frames = frames,
                images = used.values.toList(),
            ),
        )
    }

    /**
     * Whether the report is of an abort [NativeAborts] turned into a fault: the C runtime's `strlen` ([module]) read the
     * signal's number as an address (the report's `siginfo`: Linux's `si_addr: 0x…06`, Windows' `reading address
     * 0x…16`).
     */
    private fun aborted(lines: List<String>, module: String?): Boolean {
        val address = lines.firstOrNull { it.startsWith("siginfo:") }
            ?.let { FAULT_ADDRESS.find(it)?.groupValues?.get(1)?.toULongOrNull(16)?.toLong() }
        return when (module) {
            "libc.so.6" -> address == NativeAborts.LINUX_SIGABRT
            "ucrtbase.dll" -> address == NativeAborts.WINDOWS_SIGABRT
            else -> false
        }
    }

    /** A frame line with its spaces collapsed and Windows' "(no source info available)" left out. */
    private fun frameText(line: String): String = line.substringBefore(NO_SOURCE).trim().replace(Regex("""\s+"""), " ")

    private fun moduleOf(frame: String): String? = Regex("""\[([^+\]]+)""").find(frame)?.groupValues?.get(1)

    /**
     * The lines after the one starting with [title], to the next blank line or the next section's title (Linux's native
     * frames run straight into "Java frames:").
     */
    private fun section(lines: List<String>, title: String): List<String> =
        lines.indexOfFirst { it.startsWith(title) }.takeIf { it >= 0 }
            ?.let { start -> lines.drop(start + 1).takeWhile { it.isNotBlank() && !SECTION_TITLE.matches(it) } }
            .orEmpty()

    /** A section's title line: `Java frames: (J=compiled Java code, …)`. */
    private val SECTION_TITLE = Regex("""^[A-Z][a-z]+(?: [a-z]+)*:.*""")

    /** A library the crashed process had loaded: its file and the address range it was mapped at. */
    private data class Library(val path: String, val base: Long, val end: Long, val windows: Boolean) {
        val name: String get() = path.substringAfterLast('/').substringAfterLast('\\')

        /**
         * Whether a frame's module [module] (the name the library was loaded by) is this library: the same file name,
         * or on Linux a soname link to this versioned file (`libmpv.so.2` to `libmpv.so.2.5.0`).
         */
        fun loadedAs(module: String): Boolean =
            if (windows) name.equals(module, ignoreCase = true) else name == module || name.startsWith("$module.")
    }

    /**
     * The report's library list: on Windows one line per library (`0x<base> - 0x<end>: <path>`); on Linux the process's
     * memory map, a library's base its first mapping and its end its last.
     */
    private fun libraries(lines: List<String>): List<Library> {
        val windows = lines.mapNotNull(WINDOWS_LIBRARY::find).map { m ->
            Library(m.groupValues[3].trim(), m.groupValues[1].toULong(16).toLong(), m.groupValues[2].toULong(16).toLong(), windows = true)
        }
        if (windows.isNotEmpty()) return windows
        return lines.mapNotNull(LINUX_MAPPING::find)
            .groupBy { it.groupValues[3] }
            .map { (path, mappings) ->
                Library(
                    path,
                    mappings.minOf { it.groupValues[1].toULong(16) }.toLong(),
                    mappings.maxOf { it.groupValues[2].toULong(16) }.toLong(),
                    windows = false,
                )
            }
    }

    private fun image(library: Library, identify: (Path) -> NativeImages.Ids?): NativeCrash.Image {
        val ids = identify(Path.of(library.path))
        return NativeCrash.Image(
            kind = ids?.kind ?: if (library.windows) "pe" else "elf",
            codeFile = library.path,
            imageAddress = library.base,
            imageSize = library.end - library.base,
            debugId = ids?.debugId,
            codeId = ids?.codeId,
            debugFile = ids?.debugFile,
        )
    }

    /** A native frame: `C  [libmpv.so.2+0x8f00]  mp_image_unref+0x10`. */
    private val FRAME = Regex("""^\S\s+\[([^+\]]+)\+0x([0-9a-fA-F]+)\](.*)$""")
    private val WINDOWS_LIBRARY = Regex("""^0x([0-9a-fA-F]+) - 0x([0-9a-fA-F]+):?\s+(\S.*)$""")
    private val LINUX_MAPPING = Regex("""^([0-9a-f]+)-([0-9a-f]+)\s+\S+\s+[0-9a-f]+\s+\S+\s+\d+\s+(/.+?)\s*$""")

    /** The fault address in a report's `siginfo` line: Linux's `si_addr: 0x…`, Windows' `reading address 0x…`. */
    private val FAULT_ADDRESS = Regex("""(?:si_addr:|reading address) 0x([0-9a-fA-F]+)""")

    /** The C runtimes an abort runs through: its first frame outside them is what aborted. */
    private val C_RUNTIMES = setOf("libc.so.6", "ucrtbase.dll")
    private const val NO_SOURCE = "(no source info available)"

    private const val MAX_FRAMES = 64
}
