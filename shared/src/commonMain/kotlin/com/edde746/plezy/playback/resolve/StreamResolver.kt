package com.edde746.plezy.playback.resolve

import com.edde746.plezy.net.isCredentialHeader
import com.edde746.plezy.net.sameOrigin
import io.ktor.http.URLBuilder
import io.ktor.http.Url
import io.ktor.http.takeFrom

/**
 * The one rule for every hop of a media request whose redirects the app follows itself (a download's in
 * [KtorTransport][com.edde746.plezy.downloads.KtorTransport], a subtitle's in
 * [SidecarFetcher][com.edde746.plezy.playback.session.SidecarFetcher]): at most [MAX_REDIRECTS] hops; a `Location`
 * that leaves http(s), or goes from https to http, is refused ([redirectTarget]); the credential headers
 * ([com.edde746.plezy.net.CREDENTIAL_HEADERS]) go only to the first URL's scheme, host and port ([redirectHeaders]).
 * Relative `Location`s resolve against the URL that answered.
 */
object StreamResolver {
    const val MAX_REDIRECTS = 10

    /** The statuses that redirect, when their answer has a `Location`. */
    internal val REDIRECTS = setOf(301, 302, 303, 307, 308)

    /**
     * Where a `Location` [location] in the answer from [from] leads, a relative one resolved against [from]; null, the
     * hop refused, when it isn't an http(s) URL with a host or it goes from https to http.
     */
    internal fun redirectTarget(from: Url, location: String): Url? {
        val target = runCatching {
            URLBuilder(from).apply {
                parameters.clear()
                fragment = ""
                takeFrom(location)
            }.build()
        }.getOrNull() ?: return null
        val downgrade = from.protocol.name == "https" && target.protocol.name == "http"
        val http = target.protocol.name in setOf("http", "https") && target.host.isNotEmpty()
        return target.takeIf { http && !downgrade }
    }

    /**
     * The headers for a hop to [target] of a request that started at [origin], from [headers], those the hop before
     * sent: without the credential headers when [target] isn't on [origin]'s scheme, host and port. Once dropped they
     * stay dropped: a hop back to [origin] goes where another host sent it.
     */
    internal fun redirectHeaders(headers: Map<String, String>, origin: Url, target: Url): Map<String, String> =
        if (target.sameOrigin(origin)) headers else headers.filterKeys { !isCredentialHeader(it) }
}
