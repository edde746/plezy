package com.edde746.plezy.backend.net

import com.edde746.plezy.backend.MediaServerHttpErrorType
import com.edde746.plezy.backend.MediaServerHttpException
import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.log.Log
import io.ktor.client.HttpClient
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.sync.Mutex
import kotlin.concurrent.atomics.AtomicReference
import kotlin.concurrent.atomics.ExperimentalAtomicApi
import kotlin.time.Duration

/**
 * A [MediaServerHttpClient] over a server's endpoints in priority order, moving to the next one when the current fails.
 *
 * Only GETs fail over by default; a POST does when its caller says replaying it is safe (`allowEndpointFailover`).
 * Failover triggers on a transient failure or a 5xx, and only when no other failover is running and the endpoint
 * list hasn't changed since the request began. What happens then:
 * - a connection error: when the current endpoint still [validateCandidate]s, the request is sent once more in place
 *   (a dead pooled socket, not a dead server); otherwise the cascade;
 * - a timeout: when the current endpoint still answers it is kept (the request is resent in place with
 *   `retryTimeoutInPlace`, the timeout surfacing if that fails too); otherwise the cascade;
 * - a 5xx: the cascade.
 *
 * The cascade validates the endpoints after the current one in order and moves to the first that answers
 * ([onEndpointSwitch] with `persist = false`), then resends; success persists the switch (`persist = true`). No
 * fallback left, no candidate answering or the resend failing: back to the first endpoint, [onAllEndpointsExhausted]
 * (not for a cancellation), and the original failure stands. When [resetEndpoints] replaces the list while the resend is
 * pending, the resend's outcome goes to the caller and the newer endpoint state is left untouched.
 *
 * Requests may come from any thread. The failover and its callbacks run on the thread of the request that failed: a
 * receiver that is confined to one thread moves to it.
 */
class FailoverHttpClient(
    http: HttpClient,
    baseUrl: String,
    defaultHeaders: Map<String, String>,
    private val logLabel: String,
    prioritizedEndpoints: List<String>,
    private val onEndpointSwitch: suspend (newBaseUrl: String, persist: Boolean) -> Unit,
    private val onAllEndpointsExhausted: (() -> Unit)? = null,
    private val validateCandidate: (suspend (candidateBaseUrl: String) -> Boolean)? = null,
    connectTimeout: Duration = MediaServerTimeouts.CONNECT,
    responseTimeout: Duration = MediaServerTimeouts.RESPONSE,
    receiveTimeout: Duration = MediaServerTimeouts.RECEIVE,
) : MediaServerHttpClient(http, baseUrl, defaultHeaders, connectTimeout, responseTimeout, receiveTimeout) {
    private val endpointManager: EndpointFailoverManager? =
        if (prioritizedEndpoints.isNotEmpty()) EndpointFailoverManager(prioritizedEndpoints) else null
    // Held by the one failover running; requests failing meanwhile keep their own failure.
    private val failover = Mutex()

    val endpoints: List<String> get() = endpointManager?.endpoints ?: emptyList()

    /** Replaces the endpoint list, pointing at [currentBaseUrl] when it is in it. */
    fun resetEndpoints(prioritizedEndpoints: List<String>, currentBaseUrl: String? = null) {
        endpointManager?.reset(prioritizedEndpoints, currentBaseUrl)
    }

    override suspend fun get(path: String, query: Map<String, Any?>?, headers: Map<String, String>?, timeout: Duration?): MediaServerResponse =
        get(path, query, headers, timeout, allowEndpointFailover = true, retryTimeoutInPlace = false)

    suspend fun get(
        path: String,
        query: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        timeout: Duration? = null,
        allowEndpointFailover: Boolean = true,
        retryTimeoutInPlace: Boolean = false,
    ): MediaServerResponse = sendWithFailover("GET", allowEndpointFailover, retryTimeoutInPlace) { super.get(path, query, headers, timeout) }

    override suspend fun post(path: String, query: Map<String, Any?>?, headers: Map<String, String>?, body: Any?, timeout: Duration?): MediaServerResponse =
        post(path, query, headers, body, timeout, allowEndpointFailover = false)

    suspend fun post(
        path: String,
        query: Map<String, Any?>? = null,
        headers: Map<String, String>? = null,
        body: Any? = null,
        timeout: Duration? = null,
        allowEndpointFailover: Boolean = false,
    ): MediaServerResponse = sendWithFailover("POST", allowEndpointFailover, false) { super.post(path, query, headers, body, timeout) }

    private suspend fun sendWithFailover(
        verb: String,
        allowEndpointFailover: Boolean,
        retryTimeoutInPlace: Boolean,
        send: suspend () -> MediaServerResponse,
    ): MediaServerResponse {
        val generation = endpointManager?.generation
        val response = try {
            send()
        } catch (e: MediaServerHttpException) {
            if (!allowEndpointFailover || !shouldAttemptFailover(e) || !canFailover(generation)) throw e
            return failoverOnce(verb, send, e.type, retryTimeoutInPlace) ?: throw e
        }
        if (!allowEndpointFailover || !isServerError(response.statusCode) || !canFailover(generation)) return response
        return failoverOnce(verb, send, null, false) ?: response
    }

    private fun canFailover(requestGeneration: Int?): Boolean {
        val manager = endpointManager ?: return false
        return !failover.isLocked && requestGeneration == manager.generation
    }

    private suspend fun failoverOnce(
        verb: String,
        send: suspend () -> MediaServerResponse,
        failure: MediaServerHttpErrorType?,
        retryTimeoutInPlace: Boolean,
    ): MediaServerResponse? {
        val manager = endpointManager!!
        if (!failover.tryLock()) return null
        val generation = manager.generation
        try {
            when (failure) {
                MediaServerHttpErrorType.CONNECTION_ERROR -> {
                    if (currentEndpointAnswers(manager)) {
                        resendInPlace(manager, generation, verb, "connection error", send)?.let { return it }
                    }
                    if (manager.generation != generation) return null
                }
                MediaServerHttpErrorType.CONNECTION_TIMEOUT, MediaServerHttpErrorType.RECEIVE_TIMEOUT -> {
                    if (currentEndpointAnswers(manager)) {
                        if (retryTimeoutInPlace) return resendInPlace(manager, generation, verb, "timeout", send)
                        Log.i(TAG) { "$logLabel endpoint still answers after $verb timeout, keeping it" }
                        return null
                    }
                    if (manager.generation != generation) return null
                }
                else -> Unit
            }
            return cascade(manager, verb, send)
        } finally {
            failover.unlock()
        }
    }

    private suspend fun currentEndpointAnswers(manager: EndpointFailoverManager): Boolean = validate(manager.current)

    private suspend fun validate(candidate: String): Boolean {
        val validator = validateCandidate ?: return false
        return try {
            validator(candidate)
        } catch (e: CancellationException) {
            throw e
        } catch (e: MediaServerHttpException) {
            if (e.isCancellation) throw e
            false
        } catch (e: Exception) {
            false
        }
    }

    private suspend fun resendInPlace(
        manager: EndpointFailoverManager,
        generation: Int,
        verb: String,
        failure: String,
        send: suspend () -> MediaServerResponse,
    ): MediaServerResponse? {
        if (manager.generation != generation) return null
        Log.i(TAG) { "$logLabel endpoint still answers after $verb $failure, retrying in place" }
        return try {
            val response = send()
            if (isServerError(response.statusCode)) null else response
        } catch (e: MediaServerHttpException) {
            if (e.isCancellation || !shouldAttemptFailover(e)) throw e
            null
        }
    }

    private suspend fun cascade(manager: EndpointFailoverManager, verb: String, send: suspend () -> MediaServerResponse): MediaServerResponse? {
        if (!manager.hasFallback) {
            resetToPreferred(manager)
            onAllEndpointsExhausted?.invoke()
            return null
        }
        val endpoints = manager.endpoints
        val currentIndex = endpoints.indexOf(manager.current)
        if (currentIndex < 0 || currentIndex >= endpoints.size - 1) return null
        val candidateGeneration = manager.generation
        // Set once the cursor moves; a concurrent resetEndpoints (background promotion) takes ownership away from us,
        // and then the newer state is left alone.
        var ownedEndpoint: String? = null
        var ownedGeneration = -1
        fun ownsState() = ownedEndpoint != null && ownedGeneration == manager.generation && manager.current == ownedEndpoint
        try {
            val selected = endpoints.subList(currentIndex + 1, endpoints.size).firstOrNull { candidate ->
                validateCandidate == null || validate(candidate)
            }
            if (manager.generation != candidateGeneration || manager.current != endpoints[currentIndex]) return null
            if (selected == null) {
                // Validation runs before the cursor moves, so the last accepted endpoint stays authoritative.
                onAllEndpointsExhausted?.invoke()
                return null
            }
            var moved: String?
            do {
                moved = manager.moveToNext()
            } while (moved != null && moved != selected)
            if (moved != selected) return null
            ownedEndpoint = selected
            ownedGeneration = manager.generation
            Log.i(TAG) { "Switching $logLabel endpoint after $verb failure" }
            onEndpointSwitch(selected, false)
            val response = send()
            if (!ownsState()) return response
            if (response.statusCode < 400) {
                Log.i(TAG) { "$logLabel endpoint failover retry succeeded" }
                onEndpointSwitch(selected, true)
                return response
            }
            resetToPreferred(manager)
            onAllEndpointsExhausted?.invoke()
            return response
        } catch (e: Throwable) {
            if (ownsState()) {
                resetToPreferred(manager)
                val cancelled = e is CancellationException || (e is MediaServerHttpException && e.isCancellation)
                if (!cancelled) onAllEndpointsExhausted?.invoke()
            }
            throw e
        }
    }

    private suspend fun resetToPreferred(manager: EndpointFailoverManager) {
        manager.resetToFirst()?.let { onEndpointSwitch(it, false) }
    }

    private companion object {
        const val TAG = "FailoverHttp"

        fun isServerError(status: Int?) = status != null && status in 500..599

        fun shouldAttemptFailover(e: MediaServerHttpException) = e.isTransient || isServerError(e.statusCode)
    }
}

/**
 * A server's endpoints in priority order and which one is current. Empty and duplicate URLs are dropped; an empty list
 * throws. [generation] changes on every move and reset, so a request started on an older list knows it is stale. Safe
 * from any thread: every read sees one consistent list and position.
 */
@OptIn(ExperimentalAtomicApi::class)
class EndpointFailoverManager(urls: List<String>) {
    private class State(val list: List<String>, val index: Int, val generation: Int)

    private val state = AtomicReference(State(sanitize(urls), 0, 0))

    val generation: Int get() = state.load().generation
    val endpoints: List<String> get() = state.load().list
    val current: String get() = state.load().let { it.list[it.index] }
    val hasFallback: Boolean get() = state.load().let { it.index < it.list.size - 1 }

    fun moveToNext(): String? = change { if (it.index < it.list.size - 1) State(it.list, it.index + 1, it.generation + 1) else null }

    /** Back to the first endpoint; null when already there. */
    fun resetToFirst(): String? = change { if (it.index != 0) State(it.list, 0, it.generation + 1) else null }

    fun reset(urls: List<String>, currentBaseUrl: String? = null) {
        val list = sanitize(urls)
        val index = currentBaseUrl?.let { list.indexOf(it) }?.takeIf { it >= 0 } ?: 0
        change { State(list, index, it.generation + 1) }
    }

    /** Applies [next] atomically; the new current endpoint, or null when [next] declines the change. */
    private inline fun change(next: (State) -> State?): String? {
        while (true) {
            val seen = state.load()
            val updated = next(seen) ?: return null
            if (state.compareAndSet(seen, updated)) return updated.list[updated.index]
        }
    }

    private companion object {
        fun sanitize(urls: List<String>): List<String> {
            val sanitized = urls.filter { it.isNotEmpty() }.distinct()
            require(sanitized.isNotEmpty()) { "At least one endpoint is required" }
            return sanitized
        }
    }
}
