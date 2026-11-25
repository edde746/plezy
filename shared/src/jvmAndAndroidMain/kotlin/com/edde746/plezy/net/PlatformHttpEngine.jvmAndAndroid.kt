package com.edde746.plezy.net

import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import io.ktor.client.engine.HttpClientEngineConfig
import io.ktor.client.engine.HttpClientEngineFactory
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.engine.okhttp.OkHttpConfig
import okhttp3.ConnectionPool
import okhttp3.Dispatcher
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Response
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import kotlin.concurrent.Volatile

/** Requests at once to one host. */
private const val MAX_REQUESTS_PER_HOST = 12

/** How often a WebSocket pings its peer: keeps NAT mappings alive and finds a dead peer. */
private const val WEBSOCKET_PING_SECONDS = 30L

/** How long an unused connection stays open. */
private const val IDLE_CONNECTION_SECONDS = 15L

/**
 * OkHttp, each client on an [OkHttpClient] of its own, whose [IdleConnectionEviction] [closeIdleConnections] reaches:
 * at most [MAX_REQUESTS_PER_HOST] requests to a host at once, idle connections closed after [IDLE_CONNECTION_SECONDS],
 * the platform's trusted certificates ([useSystemTrust]), and WebSockets pinged every [WEBSOCKET_PING_SECONDS] (OkHttp refuses a ping interval set on a session).
 */
internal actual val platformHttpEngine: HttpClientEngineFactory<HttpClientEngineConfig> = object : HttpClientEngineFactory<OkHttpConfig> {
    override fun create(block: OkHttpConfig.() -> Unit): HttpClientEngine = OkHttp.create {
        val pool = ConnectionPool(5, IDLE_CONNECTION_SECONDS, TimeUnit.SECONDS)
        preconfigured = OkHttpClient.Builder().connectionPool(pool).addInterceptor(IdleConnectionEviction(pool))
            .pingInterval(WEBSOCKET_PING_SECONDS, TimeUnit.SECONDS).apply { useSystemTrust() }.build()
        // Ktor gives the client a new dispatcher after `preconfigured`, before `config`.
        config { dispatcher(Dispatcher().apply { maxRequestsPerHost = MAX_REQUESTS_PER_HOST }) }
        block()
    }
}

/** Trusts the certificates the platform trusts where the JDK's own roots fall short of them. */
internal expect fun OkHttpClient.Builder.useSystemTrust()

// OkHttp reuses a pooled connection without probing it (a GET), and doesn't resend a request whose read timed out.
internal actual fun HttpClient.closeIdleConnections() {
    (engine.config as? OkHttpConfig)?.preconfigured?.interceptors?.filterIsInstance<IdleConnectionEviction>()?.single()?.evictBeforeNextRequest()
}

/**
 * Closes [pool]'s idle connections on the next request's thread, before that request takes a connection. The caller of
 * [closeIdleConnections] is the main thread, where closing a connection can't happen: a TLS connection writes its
 * close_notify as it closes, which Android refuses on its main thread (`NetworkOnMainThreadException`) and which blocks
 * a desktop's UI thread while the write waits. OkHttp runs every call, and so this, on its dispatcher's threads.
 */
private class IdleConnectionEviction(private val pool: ConnectionPool) : Interceptor {
    private val requested = AtomicInteger()

    @Volatile private var done = 0

    fun evictBeforeNextRequest() {
        requested.incrementAndGet()
    }

    override fun intercept(chain: Interceptor.Chain): Response {
        if (requested.get() != done) {
            synchronized(this) {
                val request = requested.get()
                if (request != done) {
                    pool.evictAll()
                    done = request
                }
            }
        }
        return chain.proceed(chain.request())
    }
}
