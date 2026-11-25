package com.edde746.plezy.desktop

import com.edde746.plezy.crash.CrashCapture
import com.edde746.plezy.crash.CrashReport
import com.edde746.plezy.crash.NativeCrash
import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.exists
import kotlin.io.path.writeText
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield

/** HotSpot's reports of a native crash, taken into the crash database on the next start and sent from there. */
class NativeCrashesTest {
    private val root = Files.createTempDirectory("native-crashes")
    private val workingDirectory = Files.createDirectories(root.resolve("cwd"))
    private val temporary = Files.createDirectories(root.resolve("tmp"))
    private val database = root.resolve(NativeCrashes.DATABASE)

    @AfterTest
    fun cleanUp() {
        CrashCapture.sink = null
        root.toFile().deleteRecursively()
    }

    /** The library ids the tests' reports' libmpv has, read from no file. */
    private val identified = mutableListOf<Path>()
    private val identify: (Path) -> NativeImages.Ids? = { path ->
        identified.add(path)
        NativeImages.Ids("pe", "c08fa467-b8e1-b259-4c4c-44205044422e-1", "6890A5D28400000", "libmpv-2.pdb")
    }

    @Test
    fun aLibmpvCrashOnWindowsIsAFatalReportGroupedByItsFrame() {
        val report = assertNotNull(NativeCrashes.parse(WINDOWS, identify))
        assertEquals(CrashReport.Level.FATAL, report.level)
        assertEquals("Native crash: EXCEPTION_ACCESS_VIOLATION (0xc0000005) in C [libmpv-2.dll+0x5219ec0]", report.message)
        assertEquals(mapOf("crash.kind" to "native", "crash.module" to "libmpv-2.dll"), report.tags)
        assertEquals(listOf("native-crash", "C [libmpv-2.dll+0x5219ec0]"), report.fingerprint)
    }

    /** The crashing frame sits at the report's pc: libmpv's load address plus the frame's offset. */
    @Test
    fun aWindowsCrashsFrameIsAtItsAddressInLibmpvWithLibmpvsDebugIds() {
        val crash = assertNotNull(NativeCrashes.parse(WINDOWS, identify)?.nativeCrash)
        assertEquals("EXCEPTION_ACCESS_VIOLATION", crash.type)
        val libmpv = """C:\Users\user\plezy\src\desktop\mpv\build\mpv\x86_64\libmpv-2.dll"""
        assertEquals(listOf(NativeCrash.Frame(0x00007ffb270c9ec0, libmpv, null)), crash.frames)
        assertEquals(
            listOf(
                NativeCrash.Image(
                    "pe", libmpv, 0x00007ffb21eb0000, 0x8400000,
                    "c08fa467-b8e1-b259-4c4c-44205044422e-1", "6890A5D28400000", "libmpv-2.pdb",
                ),
            ),
            crash.images,
        )
        assertEquals(listOf(Path.of(libmpv)), identified, "only the libraries of the stack are read")
    }

    @Test
    fun aLinuxCrashSpansLibmpvsMappingsAndKeepsTheJavaFramesAsText() {
        val report = assertNotNull(NativeCrashes.parse(LINUX, identify))
        assertEquals("Native crash: SIGSEGV (0xb) in C [libmpv.so.2.5.0+0x2067f4] mpv_client_id+0x4", report.message)
        val crash = assertNotNull(report.nativeCrash)
        assertEquals("SIGSEGV", crash.type)
        val libmpv = "/home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0"
        assertEquals(NativeCrash.Frame(0x00007f9ee0a067f4, libmpv, "mpv_client_id+0x4"), crash.frames.first())
        assertNull(crash.frames[1].instructionAddress)
        assertEquals(
            "j  java.lang.invoke.LambdaForm\$MH+0x000000004b053c00.invoke(Ljava/lang/Object;JJ)J+10 java.base@25.0.4.1",
            crash.frames[1].function,
        )
        val image = crash.images.single()
        assertEquals(libmpv, image.codeFile)
        assertEquals(0x7f9ee0800000, image.imageAddress)
        assertEquals(0x7f9ee21e9000 - 0x7f9ee0800000, image.imageSize)
    }

    /** A frame names the library as it was loaded: `libmpv.so.2`, the link to the file the memory map shows. */
    @Test
    fun aFrameOfASonameLinkIsInItsVersionedLibrary() {
        val crash = assertNotNull(NativeCrashes.parse(LINUX.replace("[libmpv.so.2.5.0+", "[libmpv.so.2+"), identify)?.nativeCrash)
        assertEquals(0x00007f9ee0a067f4, crash.frames.first().instructionAddress)
        assertEquals(1, crash.images.size)
    }

    @Test
    fun aLibraryMissingFromTheListKeepsItsFrameWithoutAnAddress() {
        val crash = assertNotNull(NativeCrashes.parse(LINUX.replace("[libmpv.so.2.5.0+", "[libgone.so+"), identify)?.nativeCrash)
        assertEquals(NativeCrash.Frame(null, "libgone.so", "mpv_client_id+0x4"), crash.frames.first())
        assertTrue(crash.images.isEmpty())
    }

    /** An abort reaches HotSpot as strlen's fault at the signal's number; its report is the abort's, grouped by its caller. */
    @Test
    fun aLibmpvAbortOnWindowsIsAnAbortInItsCallerWithoutTheHandlersFrame() {
        val report = assertNotNull(NativeCrashes.parse(WINDOWS_ABORT, identify))
        assertEquals("Native crash: abort() in C [libmpv-2.dll+0x5245504]", report.message)
        assertEquals(mapOf("crash.kind" to "abort", "crash.module" to "libmpv-2.dll"), report.tags)
        assertEquals(listOf("native-abort", "C [libmpv-2.dll+0x5245504]"), report.fingerprint)
        val crash = assertNotNull(report.nativeCrash)
        assertEquals("SIGABRT", crash.type)
        val ucrt = """C:\Windows\System32\ucrtbase.dll"""
        val libmpv = """C:\Users\user\plezy\src\desktop\mpv\build\mpv\x86_64\libmpv-2.dll"""
        assertEquals(
            listOf(
                NativeCrash.Frame(0x00007ffb5cd40000 + 0xc1989, ucrt, null),
                NativeCrash.Frame(0x00007ffb5cd40000 + 0xa4ab1, ucrt, null),
                NativeCrash.Frame(0x00007ffb21e90000 + 0x5245504, libmpv, null),
                NativeCrash.Frame(null, null, "C  0x0000021ec370b09e"),
            ),
            crash.frames,
        )
    }

    /** Linux's HotSpot walks no further than the handler: the abort is reported, without its caller. */
    @Test
    fun aLinuxAbortIsAnAbortWithoutACaller() {
        val report = assertNotNull(NativeCrashes.parse(LINUX_ABORT, identify))
        assertEquals("Native crash: abort()", report.message)
        assertEquals(mapOf("crash.kind" to "abort"), report.tags)
        assertEquals(listOf("native-abort", "abort()"), report.fingerprint)
        assertEquals("SIGABRT", report.nativeCrash?.type)
        assertEquals(emptyList(), report.nativeCrash?.frames)
    }

    @Test
    fun aFaultInTheCLibraryAtAnotherAddressStaysACrash() {
        val report = assertNotNull(NativeCrashes.parse(LINUX_ABORT.replace("si_addr: 0x0000000000000006", "si_addr: 0x0000000000000048")))
        assertEquals("Native crash: SIGSEGV (0xb) in C [libc.so.6+0x1655d9]", report.message)
        assertEquals("SIGSEGV", report.nativeCrash?.type)
        assertEquals(listOf("native-crash", "C [libc.so.6+0x1655d9]"), report.fingerprint)
    }

    @Test
    fun textThatIsNotAFatalErrorReportIsNone() {
        assertNull(NativeCrashes.parse("Exception in thread \"main\" java.lang.IllegalStateException"))
    }

    @Test
    fun onlyThisAppsReportsAreTakenIntoTheDatabase() {
        workingDirectory.resolve("hs_err_pid100.log").writeText(WINDOWS)
        temporary.resolve("hs_err_pid200.log").writeText(LINUX)
        temporary.resolve("hs_err_pid300.log").writeText(WINDOWS.replace("com.edde746.plezy.desktop.MainKt", "org.example.Other"))
        temporary.resolve("notes.log").writeText(WINDOWS)

        NativeCrashes.collect(listOf(workingDirectory, temporary, root.resolve("missing")), database)

        assertTrue(database.resolve("hs_err_pid100.log").exists())
        assertTrue(database.resolve("hs_err_pid200.log").exists())
        assertFalse(workingDirectory.resolve("hs_err_pid100.log").exists())
        assertTrue(temporary.resolve("hs_err_pid300.log").exists(), "another program's report was taken")
        assertTrue(temporary.resolve("notes.log").exists())
        assertFalse(database.resolve("hs_err_pid300.log").exists())
    }

    @Test
    fun aCollectedCrashIsSentOnceTheReporterRunsThenDeleted() = runBlocking {
        Files.createDirectories(database)
        database.resolve("hs_err_pid100.log").writeText(WINDOWS)
        val sent = mutableListOf<CrashReport>()
        // The reporter starts after the report waits for it: the report goes once it runs, whenever that is.
        val reporting = async { NativeCrashes.report(database, wait = 1.minutes) }
        yield()
        assertEquals(emptyList(), sent)
        CrashCapture.sink = CrashCapture.Sink { sent += it; true }
        reporting.await()

        assertEquals(listOf("libmpv-2.dll"), sent.map { it.tags["crash.module"] })
        assertFalse(database.resolve("hs_err_pid100.log").exists())
    }

    @Test
    fun withCrashReportsOffACollectedCrashIsDeletedUnsent() = runBlocking {
        Files.createDirectories(database)
        database.resolve("hs_err_pid100.log").writeText(WINDOWS)

        NativeCrashes.report(database, wait = 100.milliseconds)

        assertFalse(database.resolve("hs_err_pid100.log").exists())
    }

    private companion object {
        /** Real HotSpot reports of `--crash-native-after`, cut to what the parser reads. */
        val WINDOWS = """
            #
            # A fatal error has been detected by the Java Runtime Environment:
            #
            #  EXCEPTION_ACCESS_VIOLATION (0xc0000005) at pc=0x00007ffb270c9ec0, pid=5648, tid=4400
            #
            # JRE version: OpenJDK Runtime Environment Temurin-25.0.4.1+1 (25.0.4.1+1) (build 25.0.4.1+1-LTS)
            # Problematic frame:
            # C  [libmpv-2.dll+0x5219ec0]
            #
            ---------------  T H R E A D  ---------------

            Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
            C  [libmpv-2.dll+0x5219ec0]  (no source info available)

            Dynamic libraries:
            0x00007ff731520000 - 0x00007ff73152e000   C:\Users\user\.gradle\jdks\eclipse_adoptium-25-amd64-windows.2\bin\java.exe
            0x00007ffb5f120000 - 0x00007ffb5f385000   C:\Windows\SYSTEM32\ntdll.dll
            0x00007ffb5d1e0000 - 0x00007ffb5d2a9000   C:\Windows\System32\KERNEL32.DLL
            0x00007ffb21eb0000 - 0x00007ffb2a2b0000   C:\Users\user\plezy\src\desktop\mpv\build\mpv\x86_64\libmpv-2.dll

            VM Arguments:
            java_command: com.edde746.plezy.desktop.MainKt
        """.trimIndent()

        val LINUX = """
            #
            # A fatal error has been detected by the Java Runtime Environment:
            #
            #  SIGSEGV (0xb) at pc=0x00007f9ee0a067f4, pid=3746057, tid=3746106
            #
            # Problematic frame:
            # C  [libmpv.so.2.5.0+0x2067f4]  mpv_client_id+0x4
            #
            Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
            C  [libmpv.so.2.5.0+0x2067f4]  mpv_client_id+0x4
            j  java.lang.invoke.LambdaForm${'$'}MH+0x000000004b053c00.invoke(Ljava/lang/Object;JJ)J+10 java.base@25.0.4.1

            Dynamic libraries:
            49000000-49001000 ---p 00000000 00:00 0
            7f9ee0800000-7f9ee0926000 r--p 00000000 08:02 1065005                    /home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0
            7f9ee0926000-7f9ee1c2b000 r-xp 00126000 08:02 1065005                    /home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0
            7f9ee1c2b000-7f9ee210e000 r--p 0142b000 08:02 1065005                    /home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0
            7f9ee210e000-7f9ee21df000 r--p 0190d000 08:02 1065005                    /home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0
            7f9ee21df000-7f9ee21e9000 rw-p 019de000 08:02 1065005                    /home/user/plezy/src/desktop/mpv/build/mpv/x86_64/lib/x86_64-linux-gnu/libmpv.so.2.5.0
            7fa00964c000-7fa009674000 r--p 00000000 08:02 3148615                    /usr/lib/x86_64-linux-gnu/libc.so.6

            VM Arguments:
            java_command: com.edde746.plezy.desktop.harness.TestMainKt --dev
        """.trimIndent()

        /** Real HotSpot reports of `--abort-native-after`, cut to what the parser reads. */
        val WINDOWS_ABORT = """
            #
            # A fatal error has been detected by the Java Runtime Environment:
            #
            #  EXCEPTION_ACCESS_VIOLATION (0xc0000005) at pc=0x00007ffb5ce2d130, pid=2164, tid=1324
            #
            # Problematic frame:
            # C  [ucrtbase.dll+0xed130]
            #
            siginfo: EXCEPTION_ACCESS_VIOLATION (0xc0000005), reading address 0x0000000000000016

            Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
            C  [ucrtbase.dll+0xed130]  (no source info available)
            C  [ucrtbase.dll+0xc1989]  (no source info available)
            C  [ucrtbase.dll+0xa4ab1]  (no source info available)
            C  [libmpv-2.dll+0x5245504]  (no source info available)
            C  0x0000021ec370b09e  (no source info available)

            The last pc belongs to nep_invoker_blob (printed below).
            Java frames: (J=compiled Java code, j=interpreted, Vv=VM code)
            v  ~RuntimeStub::nep_invoker_blob 0x0000021ec370b068

            Dynamic libraries:
            0x00007ffb5cd40000 - 0x00007ffb5ce8b000   C:\Windows\System32\ucrtbase.dll
            0x00007ffb21e90000 - 0x00007ffb2a290000   C:\Users\user\plezy\src\desktop\mpv\build\mpv\x86_64\libmpv-2.dll

            VM Arguments:
            java_command: com.edde746.plezy.desktop.harness.TestMainKt --dev
        """.trimIndent()

        val LINUX_ABORT = """
            #
            # A fatal error has been detected by the Java Runtime Environment:
            #
            #  SIGSEGV (0xb) at pc=0x00007fabc67e65d9, pid=3777314, tid=3777363
            #
            # Problematic frame:
            # C  [libc.so.6+0x1655d9]
            #
            siginfo: si_signo: 11 (SIGSEGV), si_code: 1 (SEGV_MAPERR), si_addr: 0x0000000000000006

            Native frames: (J=compiled Java code, j=interpreted, Vv=VM code, C=native code)
            C  [libc.so.6+0x1655d9]
            Java frames: (J=compiled Java code, j=interpreted, Vv=VM code)
            v  ~RuntimeStub::nep_invoker_blob 0x00007fabb468a7e4

            Dynamic libraries:
            7fabc6681000-7fabc66a9000 r--p 00000000 08:02 3148615                    /usr/lib/x86_64-linux-gnu/libc.so.6

            VM Arguments:
            java_command: com.edde746.plezy.desktop.harness.TestMainKt --dev
        """.trimIndent()
    }
}
