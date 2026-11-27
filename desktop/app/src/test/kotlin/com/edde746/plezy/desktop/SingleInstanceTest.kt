package com.edde746.plezy.desktop

import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.PrintStream
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.StandardOpenOption
import java.util.Collections
import java.util.concurrent.CompletableFuture
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContains
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

class SingleInstanceTest {
    private val directory = Files.createTempDirectory("single-instance").resolve("data")
    private val opened = mutableListOf<AutoCloseable>()

    @AfterTest
    fun closeEverything() = opened.asReversed().forEach { it.close() }

    private fun app(link: String? = null): SingleInstance = assertNotNull(SingleInstance.claim(directory, link)).also { opened += it }

    private fun SingleInstance.received(): List<String?> = Collections.synchronizedList(mutableListOf<String?>()).also { list -> receive { list += it } }

    private fun leftPortFile() {
        Files.createDirectories(directory)
        val closedPort = ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { it.localPort }
        Files.writeString(directory.resolve("instance.port"), "$closedPort ${"0".repeat(32)} 1\n")
    }

    /**
     * Sends [line] to the running app as any local process could (with the port file's token when [withToken]): the
     * app's answer, null when it hung up without one.
     */
    private fun connect(line: String, withToken: Boolean): String? {
        val fields = Files.readString(directory.resolve("instance.port")).trim().split(' ')
        val sent = if (withToken) "${fields.getOrElse(1) { "" }} $line" else line
        return Socket(InetAddress.getLoopbackAddress(), fields[0].toInt()).use { socket ->
            socket.soTimeout = 10_000
            try {
                socket.getOutputStream().apply { write("$sent\n".toByteArray()); flush() }
                socket.getInputStream().bufferedReader().readLine()
            } catch (e: SocketException) {
                null // The app closed the connection before reading all of it.
            }
        }
    }

    @Test
    fun aLaterStartHandsItsLinkToTheRunningAppAndStepsAside() {
        val received = app().received()
        assertNull(SingleInstance.claim(directory, "plezy://open?server=4242"))
        assertNull(SingleInstance.claim(directory, link = null))
        // The app has taken each link by the time its start returns.
        assertEquals(listOf("plezy://open?server=4242", null), received.toList())
    }

    @Test
    fun aLaterStartSaysWhichRunningAppTookIt() {
        app()
        val said = ByteArrayOutputStream()
        val stderr = System.err
        System.setErr(PrintStream(said, true))
        try {
            assertNull(SingleInstance.claim(directory, link = null))
        } finally {
            System.setErr(stderr)
        }
        assertContains(said.toString(), "Plezy is already running (process ${ProcessHandle.current().pid()}, data in $directory)")
    }

    @Test
    fun linksThatComeBeforeTheAppListensWaitForIt() {
        val app = app()
        assertNull(SingleInstance.claim(directory, "plezy://home"))
        assertEquals(listOf<String?>("plezy://home"), app.received().toList())
    }

    @Test
    fun aStartWhileTheAppShutsDownWaitsAndIsTheNextApp() {
        val app = app()
        app.stop()
        val next = CompletableFuture.supplyAsync { SingleInstance.claim(directory, "plezy://library")?.also { opened += it } }
        Thread.sleep(500)
        assertFalse(next.isDone, "the start waits while the old app holds the directory")
        app.close()
        val received = assertNotNull(next.get(10, TimeUnit.SECONDS), "the start is the next app").received()
        assertNull(SingleInstance.claim(directory, "plezy://home"))
        assertEquals(listOf<String?>("plezy://home"), received.toList())
    }

    @Test
    fun aPortFileACrashLeftBehindDoesNotStopTheNextStart() {
        leftPortFile()
        val received = app().received()
        assertNull(SingleInstance.claim(directory, "plezy://home"))
        assertEquals(listOf<String?>("plezy://home"), received.toList())
    }

    @Test
    fun aStartFailsLoudlyWhenTheAppHoldingTheDirectoryNeverAnswers() {
        leftPortFile()
        // An app that locked the directory and hung before it listened.
        FileChannel.open(directory.resolve("instance.lock"), StandardOpenOption.CREATE, StandardOpenOption.WRITE).also { opened += it }.lock()
        assertFailsWith<IOException> { SingleInstance.claim(directory, "plezy://home", patience = 500.milliseconds) }
    }

    @Test
    fun theAppTakesNothingFromAProcessWithoutItsToken() {
        val received = app().received()
        assertNull(connect("plezy://evil", withToken = false), "no answer without the token")
        assertNull(SingleInstance.claim(directory, "plezy://home"))
        assertEquals(listOf<String?>("plezy://home"), received.toList())
    }

    @Test
    fun theAppTakesOnlyAPlezyLinkAndOnlyOfALengthTheOsCanPass() {
        val received = app().received()
        // A link of a scheme the desktop doesn't register.
        assertNull(connect("https://plezy.example/item/4242", withToken = true))
        assertNull(connect("plezy://item/" + "a".repeat(300 * 1024), withToken = true))
        assertNull(SingleInstance.claim(directory, link = null))
        assertEquals(listOf<String?>(null), received.toList())
    }

    @Test
    fun aStartThatNeverFinishesItsLineHoldsUpTheNextOnesForAMomentOnly() {
        val received = app().received()
        val port = Files.readString(directory.resolve("instance.port")).trim().split(' ')[0].toInt()
        val stalled = Socket(InetAddress.getLoopbackAddress(), port).also { opened += it }
        val hungUp = CompletableFuture<Unit>()
        thread(isDaemon = true) {
            try {
                // One byte at a time, each well within a read's timeout, never the line's end.
                while (true) {
                    stalled.getOutputStream().apply { write('a'.code); flush() }
                    Thread.sleep(500)
                }
            } catch (e: IOException) {
                hungUp.complete(Unit)
            }
        }
        assertNull(SingleInstance.claim(directory, "plezy://home", patience = 10.seconds))
        assertEquals(listOf<String?>("plezy://home"), received.toList())
        hungUp.get(5, TimeUnit.SECONDS)
    }

    @Test
    fun anAppThatTakesALinkLateTakesItOnce() {
        val received = Collections.synchronizedList(mutableListOf<String?>())
        val answering = CountDownLatch(1)
        // The app's listening thread is held up (by a start's line ahead, a loaded machine) past the start's patience:
        // seconds, in which a start that stopped waiting for its answer would send the link again.
        app().receive { answering.await(); received += it }
        assertFailsWith<IOException> { SingleInstance.claim(directory, "plezy://home", patience = 8.seconds) }
        answering.countDown()
        // The app answers starts in turn: by this one's answer it has taken all it will of the first.
        assertNull(SingleInstance.claim(directory, link = null))
        assertEquals(listOf("plezy://home", null), received.toList())
    }
}
