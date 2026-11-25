package com.edde746.plezy.net

import io.ktor.client.HttpClient
import io.ktor.client.HttpClientConfig
import io.ktor.client.engine.HttpClientEngineConfig
import io.ktor.client.engine.HttpClientEngineFactory
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.plugins.UserAgent
import io.ktor.client.plugins.api.Send
import io.ktor.client.plugins.api.createClientPlugin
import io.ktor.client.plugins.websocket.WebSockets
import io.ktor.http.Url
import io.ktor.util.AttributeKey

/**
 * The app's one [HttpClient]: OkHttp on Android/JVM, Darwin on Apple. Shared code never builds its own;
 * it takes this client injected.
 *
 * - `User-Agent: Plezy/<version>`.
 * - Connect and socket (idle read) timeouts; no overall request timeout, so callers set their own per call, the body
 *   read included, and cap what they read (`MediaServerHttpClient`, `TrackerHttp`, downloads streamed to disk). A
 *   body read inside `HttpStatement.execute` goes through [readBody].
 * - Redirects are followed, and every hop that leaves the request's first scheme, host and port goes without the
 *   credential headers ([CREDENTIAL_HEADERS]): a server's token never follows its redirect to another host.
 * - No HTTP cache.
 * - WebSockets, which Open Watch Party's SDK needs for its relays (`watch/`).
 */
object PlezyHttpClient {
    const val CONNECT_TIMEOUT_MILLIS: Long = 15_000
    const val SOCKET_TIMEOUT_MILLIS: Long = 30_000

    fun userAgent(appVersion: String): String = "Plezy/$appVersion"

    fun create(appVersion: String, configure: HttpClientConfig<*>.() -> Unit = {}): HttpClient =
        create(appVersion, platformHttpEngine, configure)

    fun <T : HttpClientEngineConfig> create(
        appVersion: String,
        engine: HttpClientEngineFactory<T>,
        configure: HttpClientConfig<*>.() -> Unit = {},
    ): HttpClient = HttpClient(engine) {
        install(UserAgent) { agent = userAgent(appVersion) }
        install(HttpTimeout) {
            connectTimeoutMillis = CONNECT_TIMEOUT_MILLIS
            socketTimeoutMillis = SOCKET_TIMEOUT_MILLIS
        }
        followRedirects = true
        // Installed after Ktor's redirect plugin, so it sees each hop that plugin sends.
        install(CrossOriginCredentials)
        install(WebSockets)
        configure()
    }
}

/** The first URL of a request, which its redirect hops carry along (Ktor copies a request's attributes to each hop). */
private val RequestOrigin = AttributeKey<Url>("PlezyRequestOrigin")

/** Drops the credential headers from a hop that isn't on its request's first scheme, host and port. */
private val CrossOriginCredentials = createClientPlugin("CrossOriginCredentials") {
    on(Send) { request ->
        val url = request.url.build()
        val origin = request.attributes.computeIfAbsent(RequestOrigin) { url }
        if (!url.sameOrigin(origin)) {
            request.headers.names().filter(::isCredentialHeader).forEach(request.headers::remove)
        }
        proceed(request)
    }
}

/** OkHttp on Android and the JVM, Darwin (URLSession) on Apple platforms. */
internal expect val platformHttpEngine: HttpClientEngineFactory<HttpClientEngineConfig>

/**
 * Closes the client's idle kept-alive connections, so its next request opens a new one. A kept-alive connection can die
 * silently while the app is in the background or its network changes (a router's NAT entry dropped, a server gone): its
 * socket stays open, nothing answers on it, and the request sent on it waits out the socket timeout. Callable from the
 * main thread: it does no network I/O there (closing a TLS connection writes to it), the connections close on the next
 * request's thread before it takes one.
 */
internal expect fun HttpClient.closeIdleConnections()
