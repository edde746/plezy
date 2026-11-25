package com.edde746.plezy.desktop.discord

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import com.edde746.plezy.presentation.player.DiscordActivity
import com.edde746.plezy.presentation.player.DiscordRpc
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.io.IOException
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemoryLayout.PathElement.groupElement
import java.lang.foreign.MemorySegment
import java.lang.foreign.StructLayout
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle
import java.net.StandardProtocolFamily
import java.net.UnixDomainSocketAddress
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.ServerSocketChannel
import java.nio.channels.SocketChannel
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.io.path.deleteIfExists
import kotlin.io.path.deleteRecursively
import kotlin.io.path.ExperimentalPathApi
import kotlin.test.AfterTest
import kotlin.test.Test
import kotlin.test.assertContentEquals
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue
import kotlin.time.Duration.Companion.milliseconds

class DiscordIpcTest {
    private val folder: Path = Files.createTempDirectory("discord")
    private val socket: Path = folder.resolve("discord-ipc-0")
    private val servers = mutableListOf<FakeDiscord>()
    private val presences = mutableListOf<DesktopDiscordPresence>()

    @OptIn(ExperimentalPathApi::class)
    @AfterTest
    fun cleanUp() {
        presences.forEach { it.close() }
        servers.forEach { it.close() }
        folder.deleteRecursively()
    }

    @Test
    fun aFrameIsItsOpcodeAndLengthLittleEndianThenItsJson() {
        val bytes = DiscordFrame(DiscordRpc.OP_FRAME, """{"é":1}""").encode()
        assertContentEquals(byteArrayOf(1, 0, 0, 0, 8, 0, 0, 0), bytes.copyOf(8), "op 1, then 8 bytes: é is two in UTF-8")
        assertEquals("""{"é":1}""", bytes.copyOfRange(8, bytes.size).decodeToString())
    }

    @Test
    fun theReaderJoinsSplitFramesAndSplitsJoinedOnes() {
        val first = DiscordFrame(DiscordRpc.OP_FRAME, """{"evt":"READY"}""").encode()
        val second = DiscordFrame(DiscordRpc.OP_PING, "{}").encode()
        val reader = DiscordFrameReader()
        assertTrue(reader.add(first.copyOf(5)).isEmpty(), "half a header")
        assertTrue(reader.add(first.copyOfRange(5, 12)).isEmpty(), "the header and part of the JSON")
        val stream = first.copyOfRange(12, first.size) + second
        assertEquals(
            listOf(DiscordFrame(DiscordRpc.OP_FRAME, """{"evt":"READY"}"""), DiscordFrame(DiscordRpc.OP_PING, "{}")),
            reader.add(stream),
        )
    }

    @Test
    fun aLengthPastTheLimitDropsTheConnection() {
        val header = ByteBuffer.allocate(8).order(ByteOrder.LITTLE_ENDIAN).putInt(1).putInt(DiscordRpc.MAX_PAYLOAD_BYTES + 1).array()
        assertFailsWith<IOException> { DiscordFrameReader().add(header) }
    }

    @Test
    fun theEndpointsAreDiscordsPipesOrItsSocketsUnderTheRuntimeFolder() {
        val pipes = discordEndpoints(windows = true, env = emptyMap())
        assertEquals("\\\\.\\pipe\\discord-ipc-0", pipes.first())
        assertEquals("\\\\.\\pipe\\discord-ipc-9", pipes.last())

        val linux = discordEndpoints(windows = false, env = mapOf("XDG_RUNTIME_DIR" to "/run/user/1000", "TMPDIR" to "/tmp/x"))
        assertEquals("/run/user/1000/discord-ipc-0", linux.first())
        assertTrue("/run/user/1000/app/com.discordapp.Discord/discord-ipc-0" in linux, "Flatpak Discord")
        assertTrue("/run/user/1000/snap.discord/discord-ipc-0" in linux, "Snap Discord")

        val mac = discordEndpoints(windows = false, env = mapOf("TMPDIR" to "/var/folders/ab/T/"))
        assertEquals("/var/folders/ab/T/discord-ipc-0", mac.first())
        assertEquals("/tmp/discord-ipc-0", discordEndpoints(windows = false, env = emptyMap()).first())
    }

    @Test
    fun anActivityGoesOutAfterTheHandshakeAsItsApplicationAndNullTakesItDownAndDisconnects() {
        val discord = serve()
        val presence = presence()
        presence.publish(MOVIE)

        val handshake = discord.next()
        assertEquals(DiscordRpc.OP_HANDSHAKE, handshake.op)
        assertEquals("1", handshake.json().text("v"))
        assertEquals(APPLICATION, handshake.json().text("client_id"), "the handshake names the application the presence was made for")
        val shown = discord.next().json()
        assertEquals("SET_ACTIVITY", shown.text("cmd"))
        assertEquals(ProcessHandle.current().pid().toString(), shown.obj("args").text("pid"))
        assertEquals("Arrival", shown.obj("args").obj("activity").text("details"))

        presence.publish(null)
        val cleared = discord.next().json()
        assertEquals("SET_ACTIVITY", cleared.text("cmd"))
        assertFalse("activity" in cleared.obj("args"))
        assertEquals(CLOSED, discord.next(), "then it disconnects")
    }

    @Test
    fun discordStartedLaterGetsTheActivity() {
        val attempts = LinkedBlockingQueue<Unit>()
        val presence = presence(attempts)
        presence.publish(MOVIE)
        repeat(3) { assertNotNull(attempts.poll(5, TimeUnit.SECONDS), "it keeps trying while Discord isn't running") }

        val discord = serve()
        assertEquals(DiscordRpc.OP_HANDSHAKE, discord.next().op)
        assertEquals("Arrival", discord.next().json().obj("args").obj("activity").text("details"))
    }

    @Test
    fun discordRestartedGetsTheActivityAgain() {
        val first = serve()
        val presence = presence()
        presence.publish(MOVIE)
        first.next()
        first.next()

        first.close()
        val second = serve()
        assertEquals(DiscordRpc.OP_HANDSHAKE, second.next().op)
        assertEquals("Arrival", second.next().json().obj("args").obj("activity").text("details"))
    }

    @Test
    fun discordsPingIsAnsweredWithItsPayload() {
        val discord = serve()
        presence().publish(MOVIE)
        discord.next()
        discord.next()
        discord.send(DiscordFrame(DiscordRpc.OP_PING, """{"n":7}"""))
        assertEquals(DiscordFrame(DiscordRpc.OP_PONG, """{"n":7}"""), discord.next())
    }

    @Test
    fun aDiscordThatNeverAnswersHoldsUpNothing() {
        val discord = serve(answers = false)
        val presence = presence()
        val start = System.nanoTime()
        repeat(100) { presence.publish(MOVIE.copy(endSeconds = it.toLong())) }
        val elapsed = (System.nanoTime() - start) / 1_000_000
        assertTrue(elapsed < 100, "publishing returns at once: took $elapsed ms")
        assertEquals(DiscordRpc.OP_HANDSHAKE, discord.next().op)
        assertNull(discord.poll(300), "no activity without READY")
    }

    @Test
    fun onWindowsThePipeCarriesFramesBothWaysAndNoticesDiscordQuitting() {
        if (!windows) return
        PipeServer().use { server ->
            val pipe = assertNotNull(WindowsDiscordPipe.open(server.name), "the pipe opens")
            pipe.use {
                val buffer = ByteArray(4096)
                assertEquals(0, pipe.read(buffer), "nothing has arrived: the read returns at once")
                val handshake = DiscordFrame(DiscordRpc.OP_HANDSHAKE, DiscordRpc.handshake(APPLICATION))
                pipe.write(handshake.encode())
                assertEquals(handshake, server.read())

                val ready = DiscordFrame(DiscordRpc.OP_FRAME, """{"evt":"READY"}""")
                server.write(ready)
                val reader = DiscordFrameReader()
                val deadline = System.nanoTime() + 5_000_000_000L
                var frames = emptyList<DiscordFrame>()
                while (frames.isEmpty() && System.nanoTime() < deadline) frames = reader.add(buffer, pipe.read(buffer))
                assertEquals(listOf(ready), frames)

                server.close()
                assertFailsWith<IOException>("Discord quit: the next read fails") { pipe.read(buffer) }
            }
        }
        assertNull(WindowsDiscordPipe.open("\\\\.\\pipe\\plezy-test-nothing-${System.nanoTime()}"), "nothing serves this pipe")
    }

    @Test
    fun onWindowsADiscordThatStopsReadingFailsTheWriteInsteadOfHoldingItUp() {
        if (!windows) return
        PipeServer().use { server ->
            val pipe = assertNotNull(WindowsDiscordPipe.open(server.name))
            pipe.use {
                val frame = DiscordFrame(DiscordRpc.OP_FRAME, "x".repeat(60_000)).encode()
                val outcome = LinkedBlockingQueue<Result<Unit>>()
                val start = System.nanoTime()
                Thread { outcome += runCatching { repeat(100) { pipe.write(frame) } } }.apply { isDaemon = true }.start()
                val failure = assertNotNull(outcome.poll(10, TimeUnit.SECONDS), "the writes return within 10 s").exceptionOrNull()
                val elapsed = (System.nanoTime() - start) / 1_000_000
                assertTrue(failure is IOException, "the write gives up on Discord: $failure after $elapsed ms")
            }
        }
    }

    private fun presence(attempts: LinkedBlockingQueue<Unit>? = null) = DesktopDiscordPresence(
        applicationId = APPLICATION,
        open = {
            attempts?.offer(Unit)
            UnixDiscordPipe.open(socket.toString())
        },
        retry = 50.milliseconds,
        poll = 20.milliseconds,
        answerTimeout = 2000.milliseconds,
    ).also { presences += it }

    private fun serve(answers: Boolean = true) = FakeDiscord(socket, answers).also { servers += it }

    /** Discord's side of the IPC on a Unix socket: records the frames it gets and answers the handshake with READY. */
    private class FakeDiscord(private val path: Path, private val answers: Boolean) : AutoCloseable {
        private val server = ServerSocketChannel.open(StandardProtocolFamily.UNIX).bind(UnixDomainSocketAddress.of(path))
        private val clients = CopyOnWriteArrayList<SocketChannel>()
        private val received = LinkedBlockingQueue<DiscordFrame>()
        private val acceptor = Thread {
            while (true) {
                val client = try {
                    server.accept()
                } catch (_: IOException) {
                    break
                }
                clients += client
                Thread { serve(client) }.apply { isDaemon = true }.start()
            }
        }.apply {
            isDaemon = true
            start()
        }

        /**
         * Reads the client without blocking, as the client reads Discord: on Windows a blocking read on a Unix socket
         * sometimes never returns once the client has closed it (a write to it fails, the read waits on), so the
         * disconnect would go unseen.
         */
        private fun serve(client: SocketChannel) {
            val reader = DiscordFrameReader()
            val buffer = ByteBuffer.allocate(4096)
            try {
                client.configureBlocking(false)
                while (true) {
                    buffer.clear()
                    val count = client.read(buffer)
                    if (count < 0) break
                    if (count == 0) {
                        Thread.sleep(READ_POLL_MILLIS)
                        continue
                    }
                    for (frame in reader.add(buffer.array(), buffer.position())) {
                        received += frame
                        if (frame.op == DiscordRpc.OP_HANDSHAKE && answers) {
                            write(client, DiscordFrame(DiscordRpc.OP_FRAME, """{"cmd":"DISPATCH","evt":"READY","data":{"v":1,"user":{"id":"1"}}}"""))
                        }
                    }
                }
            } catch (_: IOException) {
                received += CLOSED // close() closed the client
                return
            }
            received += CLOSED
        }

        private fun write(client: SocketChannel, frame: DiscordFrame) {
            val bytes = ByteBuffer.wrap(frame.encode())
            while (bytes.hasRemaining()) client.write(bytes)
        }

        fun send(frame: DiscordFrame) = clients.forEach { write(it, frame) }

        fun next(): DiscordFrame = assertNotNull(poll(5000), "a frame within 5 s")

        fun poll(timeoutMillis: Long): DiscordFrame? = received.poll(timeoutMillis, TimeUnit.MILLISECONDS)

        override fun close() {
            server.close()
            clients.forEach { it.close() }
            acceptor.join(1000)
            path.deleteIfExists()
        }
    }

    /** Discord's side of a Windows named pipe, as Discord creates it (byte mode, blocking), read and written by the test. */
    private class PipeServer : AutoCloseable {
        val name = "\\\\.\\pipe\\plezy-test-discord-${System.nanoTime()}"
        private val arena = Arena.ofShared()
        private val state = arena.allocate(CAPTURE_STATE)
        private val count = arena.allocate(JAVA_INT)
        private val buffer = arena.allocate(4096)
        private val reader = DiscordFrameReader()
        private val handle = createNamedPipeW.invokeWithArguments(
            arena.allocateFrom(name, Charsets.UTF_16LE), PIPE_ACCESS_DUPLEX, 0, 1, 4096, 4096, 0, MemorySegment.NULL,
        ) as MemorySegment
        private var connected = false

        init {
            check(handle.address() != -1L) { "CreateNamedPipeW failed" }
        }

        /** Waits for the client, as Discord does; a client already there (`ERROR_PIPE_CONNECTED`) is connected. */
        private fun connect() {
            if (connected) return
            if (connectNamedPipe.int(state, handle, MemorySegment.NULL) == 0) {
                val error = state.get(JAVA_INT, LAST_ERROR)
                check(error == ERROR_PIPE_CONNECTED) { "ConnectNamedPipe failed: error $error" }
            }
            connected = true
        }

        fun read(): DiscordFrame {
            connect()
            while (true) {
                check(readFile.int(state, handle, buffer, 4096, count, MemorySegment.NULL) != 0) { "ReadFile failed" }
                val read = count.get(JAVA_INT, 0)
                val frames = reader.add(buffer.asSlice(0, read.toLong()).toArray(JAVA_BYTE))
                if (frames.isNotEmpty()) return frames.single()
            }
        }

        fun write(frame: DiscordFrame) {
            connect()
            val bytes = frame.encode()
            val data = arena.allocate(bytes.size.toLong()).copyFrom(MemorySegment.ofArray(bytes))
            check(writeFile.int(state, handle, data, bytes.size, count, MemorySegment.NULL) != 0) { "WriteFile failed" }
        }

        /** Discord quits: its end of the pipe closes. */
        override fun close() {
            if (!arena.scope().isAlive) return
            closeHandle.int(handle)
            arena.close()
        }

        private companion object {
            const val PIPE_ACCESS_DUPLEX = 3
            const val ERROR_PIPE_CONNECTED = 535
            val kernel32: SymbolLookup = SymbolLookup.libraryLookup("kernel32", Arena.global())
            val lastError: Linker.Option = Linker.Option.captureCallState("GetLastError")
            val CAPTURE_STATE: StructLayout = Linker.Option.captureStateLayout()
            val LAST_ERROR = CAPTURE_STATE.byteOffset(groupElement("GetLastError"))
            val createNamedPipeW: MethodHandle = kernel32.bind(
                "CreateNamedPipeW",
                FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_INT, ADDRESS),
            )
            val connectNamedPipe: MethodHandle = kernel32.bind("ConnectNamedPipe", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS), lastError)
            val readFile: MethodHandle = kernel32.bind("ReadFile", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS), lastError)
            val writeFile: MethodHandle = kernel32.bind("WriteFile", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS), lastError)
            val closeHandle: MethodHandle = kernel32.bind("CloseHandle", FunctionDescriptor.of(JAVA_INT, ADDRESS))
        }
    }

    private fun DiscordFrame.json(): JsonObject = Json.parseToJsonElement(json).jsonObject

    private fun JsonObject.obj(key: String) = getValue(key).jsonObject

    private fun JsonObject.text(key: String) = getValue(key).jsonPrimitive.content

    private companion object {
        val windows = System.getProperty("os.name").startsWith("Windows")

        val MOVIE = DiscordActivity("Arrival", null, null, "Arrival", 1_790_000_000, 1_790_006_960)

        /** A test Discord application: the fake takes any. */
        const val APPLICATION = "424242424242424242"

        /** What [FakeDiscord] records when a client disconnects. */
        val CLOSED = DiscordFrame(-1, "")

        /** How often [FakeDiscord] looks for what the client sent. */
        const val READ_POLL_MILLIS = 5L
    }
}
