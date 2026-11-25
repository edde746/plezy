package com.edde746.plezy.net

import io.ktor.http.HttpHeaders
import io.ktor.http.Url

/**
 * The request headers that carry a user's credentials, lowercased: HTTP's own and the media servers' token headers
 * (Plex's `X-Plex-Token`, Jellyfin's and Emby's `X-Emby-Token`, `X-MediaBrowser-Token` and `X-Emby-Authorization`).
 * They go only to the origin a request was made for: every redirect hop that leaves it drops them
 * ([PlezyHttpClient], [com.edde746.plezy.playback.resolve.StreamResolver.redirectHeaders]), and the downloader never
 * stores them.
 */
internal val CREDENTIAL_HEADERS: Set<String> = setOf(
    HttpHeaders.Authorization,
    HttpHeaders.Cookie,
    HttpHeaders.ProxyAuthorization,
    "X-Plex-Token",
    "X-Emby-Token",
    "X-MediaBrowser-Token",
    "X-Emby-Authorization",
).mapTo(HashSet()) { it.lowercase() }

internal fun isCredentialHeader(name: String): Boolean = name.lowercase() in CREDENTIAL_HEADERS

/** Whether [this] and [other] share a scheme, host and port. */
internal fun Url.sameOrigin(other: Url): Boolean =
    protocol.name == other.protocol.name && host.equals(other.host, ignoreCase = true) && port == other.port
