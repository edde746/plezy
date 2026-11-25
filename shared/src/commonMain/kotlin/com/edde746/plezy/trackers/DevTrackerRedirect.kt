package com.edde746.plezy.trackers

import io.ktor.client.plugins.api.ClientPlugin
import io.ktor.client.plugins.api.createClientPlugin
import io.ktor.http.URLBuilder
import io.ktor.http.Url
import io.ktor.http.encodedPath

/** The hosts a fake tracker server stands in for, each to its path prefix there. */
private val DEV_TRACKER_HOSTS = mapOf(
    "api.trakt.tv" to "",
    "api.simkl.com" to "/simkl",
    // Simkl's CDN (trending lists).
    "data.simkl.in" to "/simkl",
    "api.mdblist.com" to "/mdblist",
    "api.myanimelist.net" to "/mal",
    // MyAnimeList's token endpoint: /mal/v1/oauth2/..., apart from the API's /mal/v2.
    "myanimelist.net" to "/mal",
    "graphql.anilist.co" to "/anilist",
    "anilist.co" to "/anilist",
    // Plezy's OAuth relay for MyAnimeList and AniList.
    "ice.plezy.app" to "/relay",
)

/**
 * Sends the tracker services' calls (and Plezy's OAuth relay's) to the fake tracker server at [baseUrl]
 * (`tools/media/test_trackers.py`) instead of their hosts, the same path and query under each host's prefix there;
 * other requests pass. A development session's trackers install it.
 */
fun devTrackerRedirect(baseUrl: String): ClientPlugin<Unit> {
    val server = Url(baseUrl)
    return createClientPlugin("DevTrackerServer") {
        onRequest { request, _ -> request.url.toDevTracker(server) }
    }
}

/**
 * The tracker service's [url] at the fake tracker server at [baseUrl], as [devTrackerRedirect] sends it there.
 *
 * @throws IllegalArgumentException when [url]'s host is no tracker service's.
 */
@Throws(IllegalArgumentException::class)
fun devTrackerUrl(baseUrl: String, url: String): String {
    val builder = URLBuilder(url)
    require(builder.toDevTracker(Url(baseUrl))) { "$url is no tracker service's" }
    return builder.buildString()
}

/** Points this URL at the fake tracker [server], under its service's prefix there; false when its host is no service's. */
private fun URLBuilder.toDevTracker(server: Url): Boolean {
    val prefix = DEV_TRACKER_HOSTS[host] ?: return false
    protocol = server.protocol
    host = server.host
    port = server.port
    encodedPath = server.encodedPath.trimEnd('/') + prefix + encodedPath
    return true
}
