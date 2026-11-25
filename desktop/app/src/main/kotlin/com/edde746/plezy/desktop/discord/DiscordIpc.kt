package com.edde746.plezy.desktop.discord

import com.edde746.plezy.desktop.bind
import com.edde746.plezy.desktop.int
import com.edde746.plezy.presentation.player.DiscordRpc
import java.io.IOException
import java.lang.foreign.Arena
import java.lang.foreign.FunctionDescriptor
import java.lang.foreign.Linker
import java.lang.foreign.MemoryLayout.PathElement.groupElement
import java.lang.foreign.MemorySegment
import java.lang.foreign.SymbolLookup
import java.lang.foreign.ValueLayout.ADDRESS
import java.lang.foreign.ValueLayout.JAVA_BYTE
import java.lang.foreign.ValueLayout.JAVA_INT
import java.lang.invoke.MethodHandle
import java.net.UnixDomainSocketAddress
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.channels.SocketChannel
import kotlin.text.Charsets.UTF_16LE

/** One frame of Discord's IPC ([DiscordRpc]): its opcode and its JSON. */
internal data class DiscordFrame(val op: Int, val json: String) {
    /** The frame's bytes: the opcode and the JSON's length, each a little-endian 32-bit number, then the UTF-8 JSON. */
    fun encode(): ByteArray {
        val payload = json.encodeToByteArray()
        return ByteBuffer.allocate(DiscordRpc.HEADER_BYTES + payload.size).order(ByteOrder.LITTLE_ENDIAN)
            .putInt(op)
            .putInt(payload.size)
            .put(payload)
            .array()
    }
}

/**
 * Turns the bytes Discord sends, as they arrive (a frame split over reads, or several in one), into [DiscordFrame]s.
 * A length past [DiscordRpc.MAX_PAYLOAD_BYTES] or below 0 means the stream can't be followed: [add] throws
 * [IOException], and the connection is dropped.
 */
internal class DiscordFrameReader {
    private var pending = ByteArray(0)

    fun add(bytes: ByteArray, count: Int = bytes.size): List<DiscordFrame> {
        pending += bytes.copyOf(count)
        val frames = mutableListOf<DiscordFrame>()
        var offset = 0
        while (pending.size - offset >= DiscordRpc.HEADER_BYTES) {
            val header = ByteBuffer.wrap(pending, offset, DiscordRpc.HEADER_BYTES).order(ByteOrder.LITTLE_ENDIAN)
            val op = header.int
            val length = header.int
            if (length !in 0..DiscordRpc.MAX_PAYLOAD_BYTES) throw IOException("a Discord frame of $length bytes")
            val end = offset + DiscordRpc.HEADER_BYTES + length
            if (pending.size < end) break
            frames += DiscordFrame(op, pending.decodeToString(offset + DiscordRpc.HEADER_BYTES, end))
            offset = end
        }
        pending = pending.copyOfRange(offset, pending.size)
        return frames
    }
}

/** One connection to Discord's IPC, whose calls never wait for Discord to read or write. */
internal interface DiscordPipe : AutoCloseable {
    /** Sends all of [bytes]; throws [IOException] once Discord is gone. */
    fun write(bytes: ByteArray)

    /** Reads what has arrived into [into]: how many bytes, 0 when nothing has; throws [IOException] once Discord is gone. */
    fun read(into: ByteArray): Int

    override fun close()
}

/** Discord's IPC as a Unix socket (Linux, the Mac), read and written without blocking. */
internal class UnixDiscordPipe private constructor(private val channel: SocketChannel) : DiscordPipe {
    override fun write(bytes: ByteArray) {
        val buffer = ByteBuffer.wrap(bytes)
        val deadline = System.nanoTime() + WRITE_TIMEOUT_NANOS
        while (buffer.hasRemaining()) {
            if (channel.write(buffer) > 0) continue
            // Discord has left its socket's buffer full: give it a moment, then give up on it.
            if (System.nanoTime() > deadline) throw IOException("Discord isn't reading its socket")
            Thread.sleep(WRITE_RETRY_MILLIS)
        }
    }

    override fun read(into: ByteArray): Int {
        val count = channel.read(ByteBuffer.wrap(into))
        if (count < 0) throw IOException("Discord closed the socket")
        return count
    }

    override fun close() = channel.close()

    companion object {
        /** The socket at [path], or null when nothing listens there. */
        fun open(path: String): UnixDiscordPipe? {
            val channel = try {
                SocketChannel.open(UnixDomainSocketAddress.of(path))
            } catch (_: IOException) {
                return null
            }
            channel.configureBlocking(false)
            return UnixDiscordPipe(channel)
        }
    }
}

/**
 * Discord's IPC as a Windows named pipe in its non-blocking mode (`PIPE_NOWAIT`): a write takes what fits in the
 * pipe's buffer and a read only what has arrived (`PeekNamedPipe`), so neither waits for Discord. Discord leaving the
 * buffer full fails the write after a while, and Discord quitting fails the next read.
 */
internal class WindowsDiscordPipe private constructor(private val handle: MemorySegment) : DiscordPipe {
    private val arena = Arena.ofShared()
    private val buffer = arena.allocate(PIPE_BUFFER_BYTES.toLong())
    private val count = arena.allocate(JAVA_INT)
    private val state = arena.allocate(Kernel32.CAPTURE_STATE)

    override fun write(bytes: ByteArray) {
        var offset = 0
        val deadline = System.nanoTime() + WRITE_TIMEOUT_NANOS
        while (offset < bytes.size) {
            val chunk = minOf(bytes.size - offset, PIPE_BUFFER_BYTES)
            MemorySegment.copy(bytes, offset, buffer, JAVA_BYTE, 0, chunk)
            check("WriteFile", Kernel32.writeFile.int(state, handle, buffer, chunk, count, MemorySegment.NULL))
            val written = count.get(JAVA_INT, 0)
            offset += written
            if (written > 0) continue
            // Discord has left the pipe's buffer full: give it a moment, then give up on it.
            if (System.nanoTime() > deadline) throw IOException("Discord isn't reading its pipe")
            Thread.sleep(WRITE_RETRY_MILLIS)
        }
    }

    override fun read(into: ByteArray): Int {
        val nothing = MemorySegment.NULL
        check("PeekNamedPipe", Kernel32.peekNamedPipe.int(state, handle, nothing, 0, nothing, count, nothing))
        val available = count.get(JAVA_INT, 0)
        if (available == 0) return 0
        check("ReadFile", Kernel32.readFile.int(state, handle, buffer, minOf(available, into.size, PIPE_BUFFER_BYTES), count, nothing))
        val read = count.get(JAVA_INT, 0)
        MemorySegment.copy(buffer, JAVA_BYTE, 0, into, 0, read)
        return read
    }

    override fun close() {
        if (!arena.scope().isAlive) return
        Kernel32.closeHandle.int(handle)
        arena.close()
    }

    /** A failed call means the pipe is broken: Discord has quit, or closed it. */
    private fun check(function: String, result: Int) {
        if (result == 0) throw IOException("$function failed: error ${state.get(JAVA_INT, Kernel32.LAST_ERROR)}")
    }

    companion object {
        /** The pipe at [path], or null when Discord doesn't serve it (not running, or every instance taken). */
        fun open(path: String): WindowsDiscordPipe? = Arena.ofConfined().use { arena ->
            val handle = Kernel32.createFileW.invokeWithArguments(
                arena.allocateFrom(path, UTF_16LE), GENERIC_READ or GENERIC_WRITE, 0, MemorySegment.NULL, OPEN_EXISTING, 0, MemorySegment.NULL,
            ) as MemorySegment
            if (handle.address() == INVALID_HANDLE_VALUE) return null
            val mode = arena.allocateFrom(JAVA_INT, PIPE_NOWAIT)
            if (Kernel32.setNamedPipeHandleState.int(handle, mode, MemorySegment.NULL, MemorySegment.NULL) == 0) {
                Kernel32.closeHandle.int(handle)
                return null
            }
            WindowsDiscordPipe(handle)
        }

        private const val GENERIC_READ = 0x80000000.toInt()
        private const val GENERIC_WRITE = 0x40000000
        private const val OPEN_EXISTING = 3
        private const val INVALID_HANDLE_VALUE = -1L

        /** `PIPE_READMODE_BYTE | PIPE_NOWAIT`. */
        private const val PIPE_NOWAIT = 1
    }
}

/** kernel32's pipe functions, bound on first use (on Windows only). */
private object Kernel32 {
    private val kernel32 = SymbolLookup.libraryLookup("kernel32", Arena.global())
    private val lastError = Linker.Option.captureCallState("GetLastError")
    val CAPTURE_STATE = Linker.Option.captureStateLayout()
    val LAST_ERROR = CAPTURE_STATE.byteOffset(groupElement("GetLastError"))

    val createFileW: MethodHandle = kernel32.bind(
        "CreateFileW",
        FunctionDescriptor.of(ADDRESS, ADDRESS, JAVA_INT, JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, ADDRESS),
    )
    val setNamedPipeHandleState: MethodHandle = kernel32.bind(
        "SetNamedPipeHandleState",
        FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, ADDRESS),
    )
    val peekNamedPipe: MethodHandle = kernel32.bind(
        "PeekNamedPipe",
        FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS, ADDRESS),
        lastError,
    )
    val readFile: MethodHandle = kernel32.bind("ReadFile", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS), lastError)
    val writeFile: MethodHandle = kernel32.bind("WriteFile", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, JAVA_INT, ADDRESS, ADDRESS), lastError)
    val closeHandle: MethodHandle = kernel32.bind("CloseHandle", FunctionDescriptor.of(JAVA_INT, ADDRESS))
}

/**
 * Where Discord listens on this computer, in the order its own clients try them: the named pipes
 * `\\.\pipe\discord-ipc-0` to `-9` on Windows; elsewhere the sockets `discord-ipc-0` to `-9` in the first of
 * `XDG_RUNTIME_DIR`, `TMPDIR`, `TMP` and `TEMP` that is set (else `/tmp`), and in the folders the Flatpak and Snap
 * builds of Discord (and Flatpak Vesktop) put theirs under it.
 */
internal fun discordEndpoints(windows: Boolean, env: Map<String, String>): List<String> {
    val names = (0 until ENDPOINTS).map { "discord-ipc-$it" }
    if (windows) return names.map { "\\\\.\\pipe\\$it" }
    val base = listOf("XDG_RUNTIME_DIR", "TMPDIR", "TMP", "TEMP").firstNotNullOfOrNull { env[it]?.takeIf(String::isNotBlank) }
        ?.trimEnd('/') ?: "/tmp"
    return UNIX_FOLDERS.flatMap { folder -> names.map { "$base/$folder$it" } }
}

/** The first of [endpoints] Discord answers on, or null. */
internal fun openDiscordPipe(windows: Boolean, endpoints: List<String>): DiscordPipe? =
    endpoints.firstNotNullOfOrNull { if (windows) WindowsDiscordPipe.open(it) else UnixDiscordPipe.open(it) }

private const val ENDPOINTS = 10

/** Under the runtime folder: Discord's own, then Flatpak Discord's, Flatpak Discord Canary's, Snap Discord's, Flatpak Vesktop's. */
private val UNIX_FOLDERS = listOf(
    "",
    "app/com.discordapp.Discord/",
    "app/com.discordapp.DiscordCanary/",
    "snap.discord/",
    ".flatpak/dev.vencord.Vesktop/xdg-run/",
)

private const val WRITE_TIMEOUT_NANOS = 5_000_000_000L
private const val WRITE_RETRY_MILLIS = 10L
private const val PIPE_BUFFER_BYTES = 64 * 1024
