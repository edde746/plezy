package com.edde746.plezy.playback.session

import com.edde746.plezy.log.Log
import com.edde746.plezy.net.readBody
import com.edde746.plezy.net.sameOrigin
import com.edde746.plezy.playback.resolve.StreamResolver
import io.ktor.client.HttpClient
import io.ktor.client.plugins.expectSuccess
import io.ktor.client.request.header
import io.ktor.client.request.prepareGet
import io.ktor.http.HttpHeaders
import io.ktor.http.Url
import io.ktor.http.isSuccess
import io.ktor.utils.io.readBuffer
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.io.buffered
import kotlinx.io.files.FileSystem
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.files.SystemTemporaryDirectory
import kotlinx.io.readByteArray
import kotlin.time.Duration.Companion.seconds
import kotlin.uuid.Uuid

/**
 * Has a sidecar subtitle's file on this device for the engine: a remote one is fetched with the app's [http] client
 * into [directory] (within [TIMEOUT], at most [MAX_BYTES]), a local one (a download's) is used where it is. The
 * engine's `sub-add` only ever opens a local file, so a subtitle server that stalls holds up neither the engine nor the
 * playback. [directory] holds this process's fetches: the first fetch empties what an earlier run left there.
 *
 * Redirects are followed here under [StreamResolver]'s rule, so the stream's credentials stay on the stream's server.
 */
class SidecarFetcher internal constructor(
    private val http: HttpClient,
    private val directory: Path,
    private val fileSystem: FileSystem,
    private val io: CoroutineDispatcher,
) {
    /** Fetches into the system's temporary directory (the app's cache directory on Android). */
    constructor(http: HttpClient) : this(http, Path(SystemTemporaryDirectory, "plezy-subtitles"), SystemFileSystem, Dispatchers.IO)

    private val preparing = Mutex()
    private var prepared = false

    /** [http] leaving redirects to [download]. */
    private val unredirected: HttpClient by lazy { http.config { followRedirects = false } }

    /**
     * The local file of the subtitle at [url], fetched now when it is remote: [headers] (the stream's, which carry the
     * server's credentials) go with the request only when [url] is on the server of [stream], and with no hop that
     * leaves it. Null when the fetch fails, answers more than [MAX_BYTES] or doesn't finish within [TIMEOUT], which is
     * logged: the file plays on without it. Cancelling the caller cancels the fetch.
     */
    suspend fun fetch(url: String, stream: String, headers: Map<String, String>): String? {
        if (!url.startsWith("http://", ignoreCase = true) && !url.startsWith("https://", ignoreCase = true)) return url
        return try {
            val body = withTimeoutOrNull(TIMEOUT) {
                val start = Url(url)
                download(start, if (start.sameOrigin(Url(stream))) headers else emptyMap())
            }
            if (body == null) {
                Log.w(TAG) { "subtitle $url: no answer within ${TIMEOUT.inWholeSeconds} s; playing without it" }
                null
            } else {
                withContext(io) { save(url, body) }
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            Log.w(TAG, e) { "subtitle $url failed; playing without it" }
            null
        }
    }

    /**
     * GET [start] with [headers], following at most [StreamResolver.MAX_REDIRECTS] redirects: each hop sends what
     * [StreamResolver.redirectHeaders] leaves it, a `Location` [StreamResolver.redirectTarget] refuses fails the fetch.
     * The body of the first answer that isn't a redirect, which must be a success of at most [MAX_BYTES].
     */
    private suspend fun download(start: Url, headers: Map<String, String>): ByteArray {
        var url = start
        var sent = headers
        repeat(StreamResolver.MAX_REDIRECTS + 1) {
            var next: Url? = null
            val body = unredirected.prepareGet(url) {
                expectSuccess = false
                for ((name, value) in sent) header(name, value)
            }.execute { response ->
                val location = response.headers[HttpHeaders.Location]
                if (response.status.value in StreamResolver.REDIRECTS && location != null) {
                    next = checkNotNull(StreamResolver.redirectTarget(response.call.request.url, location)) {
                        "a redirect to an unsupported URL"
                    }
                    null
                } else {
                    check(response.status.isSuccess()) { "HTTP ${response.status.value}" }
                    val buffer = response.readBody { it.readBuffer(MAX_BYTES + 1) }
                    check(buffer.size <= MAX_BYTES) { "longer than $MAX_BYTES bytes" }
                    buffer.readByteArray()
                }
            }
            if (body != null) return body
            val target = checkNotNull(next)
            sent = StreamResolver.redirectHeaders(sent, start, target)
            url = target
        }
        error("more than ${StreamResolver.MAX_REDIRECTS} redirects")
    }

    private suspend fun save(url: String, body: ByteArray): String {
        preparing.withLock {
            if (!prepared) {
                if (fileSystem.exists(directory)) fileSystem.list(directory).forEach { fileSystem.delete(it, mustExist = false) }
                fileSystem.createDirectories(directory)
                prepared = true
            }
        }
        val file = Path(directory, Uuid.random().toString() + extension(url))
        fileSystem.sink(file).buffered().use { it.write(body) }
        return file.toString()
    }

    private companion object {
        const val TAG = "SidecarFetcher"

        /** How long a subtitle's fetch may take before the file plays on without it. */
        val TIMEOUT = 10.seconds

        /** The largest subtitle file fetched: a subtitle with its fonts attached stays well under it. */
        const val MAX_BYTES = 32L * 1024 * 1024

        private val EXTENSION = Regex("\\.([A-Za-z0-9]{2,4})$")

        /** The subtitle's format as its URL's file name says (`.srt`, `.ass`), so mpv reads it as that; else none. */
        fun extension(url: String): String = EXTENSION.find(Url(url).encodedPath)?.value.orEmpty()
    }
}
