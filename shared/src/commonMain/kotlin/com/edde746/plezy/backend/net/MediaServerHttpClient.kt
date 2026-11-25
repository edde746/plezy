package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.log.Log
import com.edde746.plezy.net.readBody
import com.edde746.plezy.net.readText
import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.plugins.HttpTimeoutConfig
import io.ktor.client.plugins.timeout
import io.ktor.client.request.header
import io.ktor.client.request.prepareRequest
import io.ktor.client.request.setBody
import io.ktor.client.request.url
import io.ktor.client.statement.HttpResponse
import io.ktor.http.ContentType
import io.ktor.http.HttpHeaders
import io.ktor.http.HttpMethod
import io.ktor.http.Url
import io.ktor.http.contentLength
import io.ktor.utils.io.ByteReadChannel
import io.ktor.utils.io.readAvailable
import io.ktor.utils.io.readBuffer
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.getAndUpdate
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.updateAndGet
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.io.Buffer
import kotlinx.io.files.Path
import kotlinx.io.files.SystemFileSystem
import kotlinx.io.readByteArray
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import kotlin.concurrent.Volatile
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * A server's answer. [data] is the decoded JSON body (null when empty or not JSON), [text] the body text when it isn't
 * JSON. [effectiveUri] is where redirects ended.
 */
data class MediaServerResponse(
    val statusCode: Int,
    val data: JsonElement?,
    val headers: Map<String, String>,
    val requestUri: Url,
    val effectiveUri: Url = requestUri,
    val text: String? = null,
)

/** Throws a [MediaServerHttpException] carrying the status and body for a status of 400 or more. */
fun throwIfHttpError(response: MediaServerResponse) {
    if (response.statusCode >= 400) {
        throw MediaServerHttpException(
            MediaServerHttpErrorType.UNKNOWN,
            "HTTP ${response.statusCode}",
            statusCode = response.statusCode,
            responseData = response.data ?: response.text?.let(::JsonPrimitive),
            requestUri = response.requestUri,
        )
    }
}

/**
 * The request layer every media-server client sends through, over the app's [http] client.
 *
 * A path is resolved against [baseUrl] (`base + "/" + path` without its leading slash; an absolute `http(s)` URL is
 * used as is); query parameters join a query the path already has with `&`. [defaultHeaders] are merged under each
 * call's headers. Timing per request: the wait for the response headers is bounded by the call's `timeout`, else
 * [connectTimeout] + [responseTimeout]; reading the body by the call's `timeout`, else [receiveTimeout]. The connect
 * itself is bounded by [connectTimeout]: by the engine on Android and desktop (OkHttp), and on Apple, whose URLSession
 * has no connect timeout, by a direct TCP connect to the request's host and port that runs alongside the request
 * ([connectProbe]). Any of these running out throws a connection-timeout [MediaServerHttpException]; every transport
 * failure throws one ([MediaServerHttpException.from]). Each request runs on [dispatcher] (by default its engine's),
 * from its pipeline to its body decoded (UTF-8, then JSON): its caller resumes once, with the answer, so a busy caller's
 * thread (the UI's, drawing a frame) never holds a request up between its steps. A JSON or text body over
 * [MAX_BODY_BYTES] fails. Requests, [baseUrl] and [defaultHeaders] may be used from any thread.
 *
 * [close] cancels the requests in flight (their callers get a cancelled [MediaServerHttpException]) and refuses new
 * ones, a request starting at that moment included; [closeGracefully] does the same and waits up to its drain timeout
 * for them to settle. The shared [http] client stays open.
 */
open class MediaServerHttpClient(
    private val http: HttpClient,
    @Volatile var baseUrl: String = "",
    defaultHeaders: Map<String, String> = emptyMap(),
    val connectTimeout: Duration = MediaServerTimeouts.CONNECT,
    val responseTimeout: Duration = MediaServerTimeouts.RESPONSE,
    val receiveTimeout: Duration = MediaServerTimeouts.RECEIVE,
    private val dispatcher: CoroutineDispatcher = http.engine.dispatcher,
) {
    @Volatile
    var defaultHeaders: Map<String, String> = defaultHeaders.toMap()

    // The requests in flight; null once the client is closing.
    private val active = MutableStateFlow<Set<Job>?>(emptySet())
    private val awaitConnect = connectProbe(http.engine)

    open suspend fun get(path: String, query: Map<String, Any?>? = null, headers: Map<String, String>? = null, timeout: Duration? = null): MediaServerResponse =
        send(HttpMethod.Get, path, query, headers, null, timeout)

    open suspend fun post(
        path: String,
        query: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        body: Any? = null,
        timeout: Duration? = null,
    ): MediaServerResponse = send(HttpMethod.Post, path, query, headers, body, timeout)

    open suspend fun put(
        path: String,
        query: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        body: Any? = null,
        timeout: Duration? = null,
    ): MediaServerResponse = send(HttpMethod.Put, path, query, headers, body, timeout)

    open suspend fun delete(path: String, query: Map<String, Any?>? = null, headers: Map<String, String>? = null, timeout: Duration? = null): MediaServerResponse =
        send(HttpMethod.Delete, path, query, headers, null, timeout)

    /**
     * The body's bytes; a non-2xx status throws. With [maxBytes], a declared length past it fails before reading and a
     * longer stream fails once it passes it.
     */
    suspend fun getBytes(url: String, headers: Map<String, String>? = null, timeout: Duration? = null, maxBytes: Long? = null): ByteArray =
        perform(HttpMethod.Get, url, null, headers, null, timeout, "GET") { response, uri ->
            val status = response.status.value
            if (status !in 200..299) {
                throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP $status", statusCode = status, requestUri = uri)
            }
            val declared = response.contentLength()
            if (maxBytes != null && declared != null && declared > maxBytes) throw bodyTooLarge(status, uri, maxBytes, declared)
            receive(uri, timeout) {
                response.readBody { channel -> readCapped(channel, maxBytes, status, uri) }
            }
        }

    /**
     * Streams [url] into `<path>.download`, then renames it over [path]. A non-2xx status throws; any failure removes
     * the partial file.
     */
    suspend fun downloadFile(url: String, path: String, headers: Map<String, String>? = null, timeout: Duration? = null) {
        val target = Path(path)
        val temp = Path("$path.download")
        try {
            perform(HttpMethod.Get, url, null, headers, null, timeout, "download") { response, uri ->
                val status = response.status.value
                if (status !in 200..299) {
                    throw MediaServerHttpException(MediaServerHttpErrorType.UNKNOWN, "HTTP $status", statusCode = status, requestUri = uri)
                }
                target.parent?.let { SystemFileSystem.createDirectories(it) }
                if (SystemFileSystem.exists(temp)) SystemFileSystem.delete(temp)
                receive(uri, timeout) {
                    response.readBody { channel ->
                        SystemFileSystem.sink(temp).use { sink ->
                            val chunk = ByteArray(CHUNK_BYTES)
                            val buffer = Buffer()
                            while (true) {
                                val read = channel.readAvailable(chunk, 0, chunk.size)
                                if (read < 0) break
                                buffer.write(chunk, 0, read)
                                sink.write(buffer, buffer.size)
                            }
                            sink.flush()
                        }
                    }
                }
                if (SystemFileSystem.exists(target)) SystemFileSystem.delete(target)
                SystemFileSystem.atomicMove(temp, target)
            }
        } catch (e: Throwable) {
            runCatching { if (SystemFileSystem.exists(temp)) SystemFileSystem.delete(temp) }
            throw e
        }
    }

    /** [path] and [query] resolved against [baseUrl] as a request would be. */
    fun buildUri(path: String, query: Map<String, Any?>? = null): Url = resolveUri(path, query)

    fun close() {
        active.getAndUpdate { null }?.forEach { it.cancel() }
    }

    suspend fun closeGracefully(drainTimeout: Duration = 2.seconds) {
        val inFlight = active.getAndUpdate { null } ?: return
        inFlight.forEach { it.cancel() }
        withTimeoutOrNull(drainTimeout) { inFlight.joinAll() }
    }

    private suspend fun send(method: HttpMethod, path: String, query: Map<String, Any?>?, headers: Map<String, String>?, body: Any?, timeout: Duration?) =
        perform(method, path, query, headers, body, timeout, method.value) { response, uri ->
            val status = response.status.value
            val text = receive(uri, timeout) { response.readText(MAX_BODY_BYTES) } ?: throw bodyTooLarge(status, uri, MAX_BODY_BYTES, null)
            val responseHeaders = response.headers.entries().associate { (name, values) -> name to values.joinToString(",") }
            val effective = response.call.request.url
            if (text.isEmpty()) return@perform MediaServerResponse(status, null, responseHeaders, uri, effective)
            val isJson = response.headers[HttpHeaders.ContentType]?.contains("json", ignoreCase = true) == true
            val (data, plain) = decodeBody(text, isJson, status, uri)
            MediaServerResponse(status, data, responseHeaders, uri, effective, plain)
        }

    private suspend fun <T> perform(
        method: HttpMethod,
        url: String,
        query: Map<String, Any?>?,
        headers: Map<String, String>?,
        body: Any?,
        timeout: Duration?,
        operation: String,
        consume: suspend (HttpResponse, Url) -> T,
    ): T = onDispatcher {
        val uri = resolveUri(url, query)
        val started = TimeSource.Monotonic.markNow()
        val statement = http.prepareRequest {
            this.method = method
            url(uri)
            timeout {
                connectTimeoutMillis = connectTimeout.inWholeMilliseconds
                socketTimeoutMillis = (timeout ?: receiveTimeout).inWholeMilliseconds
                requestTimeoutMillis = HttpTimeoutConfig.INFINITE_TIMEOUT_MS
            }
            val merged = LinkedHashMap<String, String>()
            for ((name, value) in defaultHeaders) merged[name.lowercase()] = value
            headers?.forEach { (name, value) -> merged[name.lowercase()] = value }
            for ((name, value) in merged) header(name, value)
            when (body) {
                null -> Unit
                is ByteArray -> setBody(body)
                is String -> setBody(body)
                is JsonElement -> {
                    if (HttpHeaders.ContentType.lowercase() !in merged) header(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                    setBody(body.toString())
                }
                else -> throw IllegalArgumentException("Unsupported request body ${body::class.simpleName}")
            }
        }
        try {
            coroutineScope {
                val headersArrived = CompletableDeferred<Unit>()
                val connectTimedOut = CompletableDeferred<Unit>()
                val work = async(start = CoroutineStart.LAZY) {
                    statement.execute { response ->
                        headersArrived.complete(Unit)
                        consume(response, uri)
                    }
                }
                if (!admit(work)) {
                    work.cancel()
                    throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "HTTP client is closing", requestUri = uri)
                }
                work.start()
                val probe = awaitConnect?.let { connect ->
                    launch { withTimeoutOrNull(connectTimeout) { connect(uri) } ?: connectTimedOut.complete(Unit) }
                }
                try {
                    try {
                        withTimeout(timeout ?: (connectTimeout + responseTimeout)) {
                            select<Unit> {
                                headersArrived.onAwait {}
                                work.onJoin {}
                                connectTimedOut.onAwait {
                                    work.cancel()
                                    throw MediaServerHttpException(
                                        MediaServerHttpErrorType.CONNECTION_TIMEOUT,
                                        "$operation ${uri.encodedPath} connect timed out",
                                        requestUri = uri,
                                    )
                                }
                            }
                        }
                        probe?.cancel()
                    } catch (e: TimeoutCancellationException) {
                        work.cancel()
                        throw MediaServerHttpException(
                            MediaServerHttpErrorType.CONNECTION_TIMEOUT,
                            "$operation ${uri.encodedPath} response timed out",
                            requestUri = uri,
                            cause = e,
                        )
                    }
                    work.await()
                } finally {
                    untrack(work)
                }
            }.also { Log.d(TAG) { "$operation ${uri.host}${uri.encodedPath} (${started.elapsedNow().inWholeMilliseconds}ms)" } }
        } catch (e: CancellationException) {
            currentCoroutineContext().ensureActive()
            // The caller is alive: this request was cancelled by close().
            throw MediaServerHttpException(MediaServerHttpErrorType.CANCELLED, "Request aborted", requestUri = uri, cause = e)
        } catch (e: Exception) {
            throw MediaServerHttpException.from(e, uri)
        }
    }

    /**
     * Runs [block] on [dispatcher]. One that never dispatches (`Unconfined`) has no thread to move to: [block] runs in
     * place, its timeouts kept on the caller's clock, which a switch to it would drop.
     */
    private suspend fun <T> onDispatcher(block: suspend CoroutineScope.() -> T): T =
        if (dispatcher.isDispatchNeeded(currentCoroutineContext())) withContext(dispatcher, block) else coroutineScope(block)

    /** Bounds a body read by the call's timeout, else [receiveTimeout]. */
    private suspend fun <T> receive(uri: Url, timeout: Duration?, block: suspend () -> T): T = try {
        withTimeout(timeout ?: receiveTimeout) { block() }
    } catch (e: TimeoutCancellationException) {
        throw MediaServerHttpException(MediaServerHttpErrorType.CONNECTION_TIMEOUT, "${uri.encodedPath} receive timed out", requestUri = uri, cause = e)
    }

    /** Registers [job] as in flight; false once the client is closing, atomically with [close]'s snapshot. */
    private fun admit(job: Job): Boolean = active.updateAndGet { it?.plus(job) } != null

    private fun untrack(job: Job) = active.update { it?.minus(job) }

    private fun resolveUri(url: String, query: Map<String, Any?>?): Url {
        val raw = if (url.startsWith("http://") || url.startsWith("https://")) {
            url
        } else {
            val base = if (baseUrl.endsWith('/')) baseUrl else "$baseUrl/"
            base + url.removePrefix("/")
        }
        val extra = encodeQueryParameters(query)
        if (extra.isEmpty()) return Url(raw)
        val fragmentAt = raw.indexOf('#')
        val beforeFragment = if (fragmentAt >= 0) raw.substring(0, fragmentAt) else raw
        val fragment = if (fragmentAt >= 0) raw.substring(fragmentAt) else ""
        val joined = when {
            '?' !in beforeFragment -> "$beforeFragment?$extra"
            beforeFragment.endsWith('?') || beforeFragment.endsWith('&') -> beforeFragment + extra
            else -> "$beforeFragment&$extra"
        }
        return Url(joined + fragment)
    }

    private companion object {
        const val TAG = "MediaServerHttp"
        const val CHUNK_BYTES = 64 * 1024

        /** The most a JSON or text answer may hold; a library page is far smaller, and a runaway body stops here. */
        const val MAX_BODY_BYTES = 64L * 1024 * 1024

        /** The body parsed as JSON when [isJson] (with null text), else its text (with null JSON). */
        fun decodeBody(text: String, isJson: Boolean, status: Int, uri: Url): Pair<JsonElement?, String?> {
            if (!isJson) return null to text
            return try {
                Json.parseToJsonElement(text) to null
            } catch (e: Exception) {
                throw MediaServerHttpException(
                    MediaServerHttpErrorType.UNKNOWN,
                    "Failed to decode response body: ${e.message}",
                    statusCode = status,
                    responseData = JsonPrimitive(text),
                    requestUri = uri,
                    cause = e,
                )
            }
        }

        /** The whole body; with [maxBytes], one longer than that fails once it passes it. */
        suspend fun readCapped(channel: ByteReadChannel, maxBytes: Long?, status: Int, uri: Url): ByteArray {
            val body = if (maxBytes == null) channel.readBuffer() else channel.readBuffer(maxBytes + 1)
            if (maxBytes != null && body.size > maxBytes) throw bodyTooLarge(status, uri, maxBytes, null)
            return body.readByteArray()
        }

        fun bodyTooLarge(status: Int, uri: Url, maxBytes: Long, declared: Long?) = MediaServerHttpException(
            MediaServerHttpErrorType.UNKNOWN,
            "Response body${declared?.let { " of $it bytes" } ?: ""} exceeds the $maxBytes-byte limit",
            statusCode = status,
            requestUri = uri,
        )
    }
}

/**
 * For an [engine] that doesn't bound the connect itself: suspends until a direct TCP connect to the URL's host and port
 * completes, or returns at once when the URL goes through a proxy. Null for an engine that bounds the connect, or that
 * makes no connection of its own.
 */
internal expect fun connectProbe(engine: HttpClientEngine): (suspend (Url) -> Unit)?
