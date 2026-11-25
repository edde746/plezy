package com.edde746.plezy.desktop

import com.edde746.plezy.desktop.windows.WindowsForeground
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.net.SocketTimeoutException
import java.nio.channels.FileChannel
import java.nio.channels.OverlappingFileLockException
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission
import java.nio.file.attribute.PosixFilePermissions
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.HexFormat
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

private val isWindows = System.getProperty("os.name").startsWith("Windows")

/**
 * One app per data directory. The first start on a
 * directory locks `instance.lock` there and listens on a loopback port it writes to `instance.port`, with a random
 * token and its process id (a file only its user can read). A later
 * start, such as the one the OS makes for a `plezy://` link while Plezy runs, sends that app the token and its link
 * (the token alone for a plain start, which brings the window forward) and exits once the app answers `ok`; on Windows
 * it first lets the app's process take the foreground, which Windows otherwise keeps from a process the user didn't
 * just start. It waits for that answer as long as its patience lasts and sends its link again only when the app hung up
 * without taking it, so the app takes each start's link once, however late it answers. The app takes nothing else: a
 * line without the token, longer than [MAX_LINE_BYTES] or unfinished after [READ_TIMEOUT_MILLIS], or whose link isn't a
 * `plezy:` link (the one scheme the desktop registers and the one a user can pass on the command line) is refused
 * unanswered. While the app shuts down, a start waits for
 * it to end and is the next app. The OS releases the lock when the process ends, however it ends, so a crashed app
 * holds nothing and the next start writes a new port file over the old one.
 */
internal class SingleInstance private constructor(
    private val directory: Path,
    private val channel: FileChannel,
    private val server: ServerSocket,
    private val token: String,
) : AutoCloseable {
    private val pending = mutableListOf<String?>()
    private var receiver: ((String?) -> Unit)? = null

    init {
        Thread(::serve, "single-instance").apply { isDaemon = true; start() }
    }

    /**
     * Hands [receiver] each later start's link, null for a plain start: the ones that came before this call at once,
     * the rest as they come, on the listening thread.
     */
    fun receive(receiver: (String?) -> Unit) {
        synchronized(pending) {
            this.receiver = receiver
            pending.forEach(receiver)
            pending.clear()
        }
    }

    /** Stops taking links (the app is shutting down): a start from now on waits until [close], then is the next app. */
    fun stop() {
        server.close()
        // While the lock is still held: the port file is this app's.
        Files.deleteIfExists(directory.resolve(PORT_FILE))
    }

    /** Gives the directory up once the app has let go of it (its database closed): the next start is its app. */
    override fun close() {
        stop()
        channel.close()
    }

    private fun deliver(link: String?) {
        synchronized(pending) {
            val receiver = receiver
            if (receiver != null) receiver(link) else pending += link
        }
    }

    private fun serve() {
        while (true) {
            val socket = try {
                server.accept()
            } catch (e: SocketException) {
                if (server.isClosed) return
                throw e
            }
            socket.use {
                try {
                    deliver(linkIn(firstLine(it)))
                    it.getOutputStream().apply { write("ok\n".toByteArray()); flush() }
                } catch (e: IOException) {
                    System.err.println("plezy: took no link from a later start: ${e.message}")
                }
            }
        }
    }

    /** The link a start's [line] carries, null for a plain start; refused unless it begins with this app's token. */
    private fun linkIn(line: String): String? {
        if (!MessageDigest.isEqual(line.substringBefore(' ').toByteArray(), token.toByteArray())) throw IOException("it sent no token or a wrong one")
        val link = line.substringAfter(' ', missingDelimiterValue = "").ifEmpty { return null }
        if (!link.startsWith(LINK_SCHEME, ignoreCase = true)) throw IOException("its link isn't a $LINK_SCHEME link")
        return link
    }

    /** The running app as its port file names it. */
    private class Running(val port: Int, val token: String, val pid: Long)

    /** The app has a start's link but hasn't answered: it may still take it, so the start doesn't send it again. */
    private class Unanswered(cause: SocketTimeoutException) : IOException("it has the link but didn't answer", cause)

    companion object {
        private const val LOCK_FILE = "instance.lock"
        private const val PORT_FILE = "instance.port"
        private const val READ_TIMEOUT_MILLIS = 5_000
        private const val LINK_SCHEME = "plezy:"
        private const val NEWLINE: Byte = 10

        /**
         * The longest line the app reads: the token and more than any link the OS can pass a start (Windows' command
         * line is 32 767 characters, a Linux argument 128 KiB).
         */
        private const val MAX_LINE_BYTES = 256 * 1024

        /**
         * Makes this process [directory]'s app and returns it, or sends [link] to the app running there and returns
         * null. Until one of the two happens it tries again: the port file can still be the last app's while the
         * running one starts, and an app shutting down takes no links. It doesn't once the running app has the link,
         * since that app may take it however late it answers: it waits for the answer instead.
         *
         * @throws IOException when another app holds [directory] but hasn't answered within [patience].
         */
        fun claim(directory: Path, link: String?, patience: Duration = 20.seconds): SingleInstance? {
            Files.createDirectories(directory)
            val deadline = TimeSource.Monotonic.markNow() + patience
            var failure: IOException? = null
            while (true) {
                val channel = FileChannel.open(directory.resolve(LOCK_FILE), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
                val locked = try {
                    channel.tryLock() != null
                } catch (e: OverlappingFileLockException) {
                    // An app in this JVM holds it.
                    false
                }
                if (locked) return listen(directory, channel)
                channel.close()
                try {
                    if (send(running(directory.resolve(PORT_FILE)), link, deadline)) return null
                } catch (e: IOException) {
                    failure = e
                }
                if (failure is Unanswered || deadline.hasPassedNow()) throw IOException("Plezy is running on $directory but didn't answer within $patience", failure)
                Thread.sleep(100)
            }
        }

        /** The app on [channel], whose lock this process holds: listening, its port, token and process in the port file. */
        private fun listen(directory: Path, channel: FileChannel): SingleInstance {
            val server = ServerSocket(0, 50, InetAddress.getLoopbackAddress())
            val token = HexFormat.of().formatHex(ByteArray(16).also(SecureRandom()::nextBytes))
            val temporary = directory.resolve("$PORT_FILE.tmp")
            Files.deleteIfExists(temporary)
            // Readable by this user alone (on Windows the profile's folders are already).
            if ("posix" in FileSystems.getDefault().supportedFileAttributeViews()) {
                Files.createFile(temporary, PosixFilePermissions.asFileAttribute(setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE)))
            }
            Files.writeString(temporary, "${server.localPort} $token ${ProcessHandle.current().pid()}\n")
            Files.move(temporary, directory.resolve(PORT_FILE), StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
            return SingleInstance(directory, channel, server, token)
        }

        /**
         * True once the app [running] has taken [link] (answered `ok`), false when it hung up without taking it;
         * [Unanswered] when it has the link but hasn't answered by [deadline].
         */
        private fun send(running: Running, link: String?, deadline: TimeMark): Boolean {
            if (isWindows) WindowsForeground.allow(running.pid)
            return Socket().use { socket ->
                socket.connect(InetSocketAddress(InetAddress.getLoopbackAddress(), running.port), 1_000)
                socket.getOutputStream().apply { write("${running.token} ${link.orEmpty()}\n".toByteArray()); flush() }
                socket.soTimeout = (-deadline.elapsedNow()).inWholeMilliseconds.coerceIn(1, Int.MAX_VALUE.toLong()).toInt()
                try {
                    socket.getInputStream().bufferedReader().readLine() == "ok"
                } catch (e: SocketTimeoutException) {
                    throw Unanswered(e)
                }
            }
        }

        private fun running(file: Path): Running {
            val fields = Files.readString(file).trim().split(' ')
            val port = fields.getOrNull(0)?.toIntOrNull()?.takeIf { it in 1..65535 }
            val pid = fields.getOrNull(2)?.toLongOrNull()
            if (fields.size != 3 || port == null || fields[1].isEmpty() || pid == null) throw IOException("$file holds no port, token and process")
            return Running(port, fields[1], pid)
        }

        /**
         * The first line [socket] sends, without its end; refused past [MAX_LINE_BYTES] or [READ_TIMEOUT_MILLIS] after
         * it connected, so a start that never finishes its line holds up the ones after it for that long at most.
         */
        private fun firstLine(socket: Socket): String {
            val deadline = TimeSource.Monotonic.markNow() + READ_TIMEOUT_MILLIS.milliseconds
            val input = socket.getInputStream()
            val line = ByteArrayOutputStream()
            val chunk = ByteArray(8 * 1024)
            while (true) {
                val left = -deadline.elapsedNow()
                if (!left.isPositive()) throw IOException("it didn't send its line within $READ_TIMEOUT_MILLIS ms")
                socket.soTimeout = left.inWholeMilliseconds.toInt().coerceAtLeast(1)
                val read = input.read(chunk)
                if (read == -1) throw IOException("the start hung up before sending its link")
                var end = 0
                while (end < read && chunk[end] != NEWLINE) end++
                line.write(chunk, 0, end)
                if (line.size() > MAX_LINE_BYTES) throw IOException("its line is longer than $MAX_LINE_BYTES bytes")
                if (end < read) return line.toString(Charsets.UTF_8)
            }
        }
    }
}
