package com.edde746.plezy.plex

import com.edde746.plezy.backend.MediaServerTimeouts
import com.edde746.plezy.backend.net.EndpointRacePhase
import com.edde746.plezy.backend.net.raceEndpointCandidates
import io.ktor.client.HttpClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/**
 * The server's working connections, best last: the first that answers (IPv6 held until every IPv4 direct candidate
 * failed, relay until every direct one did; a cached fallback-tier URL gets no head start), then its HTTPS upgrade when
 * that answers, then the latency sweep's pick when it differs (local > remote > relay, IPv4 > IPv6, HTTPS > HTTP, lowest
 * latency, plex.direct on ties). Nothing is emitted when no candidate works. [onFirstSuccess] gets the first success's
 * probe, with what it read from the root.
 */
fun PlexServer.findBestWorkingConnection(
    httpClient: HttpClient,
    preferredUri: String? = null,
    clientIdentifier: String? = null,
    deviceName: String? = null,
    onFirstSuccess: ((ConnectionTestResult) -> Unit)? = null,
): Flow<PlexConnection> = flow {
    val candidates = prioritizedCandidates()
    if (candidates.isEmpty()) return@flow
    var firstConnection: PlexConnection? = null
    suspend fun probe(url: String, timeout: kotlin.time.Duration) =
        PlexClient.testConnectionWithLatency(httpClient, url, accessToken, timeout, clientIdentifier, deviceName)

    raceEndpointCandidates(
        label = "Plex server connection",
        candidates = candidates,
        urlOf = { it.url },
        probe = { candidate, timeout -> probe(candidate.url, timeout) },
        measure = {
            PlexClient.testConnectionWithAverageLatency(
                httpClient, it.url, accessToken, attempts = 2, clientIdentifier = clientIdentifier, deviceName = deviceName,
            )
        },
        isSuccess = { it.success },
        selectBestCandidate = ::selectBestCandidate,
        preferredUrl = preferredUri,
        candidateForUrl = ::candidateForUrl,
        tierOf = { PlexServer.raceTier(it.connection) },
        displayTypeOf = { it.connection.displayType },
        onFirstSuccess = { _, result -> onFirstSuccess?.invoke(result) },
    ).collect { selection ->
        val upgrade: suspend () -> PlexConnectionCandidate? = {
            upgradeToHttps(selection.candidate) { url -> probe(url, MediaServerTimeouts.CONNECTION_RACE).success }
        }
        if (selection.phase == EndpointRacePhase.FIRST) {
            // The winner goes out before its HTTPS upgrade is probed: the upgrade must not gate startup.
            val first = selection.candidate.toConnection()
            firstConnection = first
            emit(first)
            val upgraded = upgrade()
            if (upgraded != null && upgraded.url != selection.candidate.url) {
                firstConnection = upgraded.toConnection()
                emit(upgraded.toConnection())
            }
        } else {
            val best = (upgrade() ?: selection.candidate).toConnection()
            if (best.uri != firstConnection?.uri) emit(best)
        }
    }
}

private fun PlexConnectionCandidate.toConnection(): PlexConnection = if (url == connection.uri) connection else connection.copy(uri = url)

/**
 * The HTTPS twin of an http candidate when one can present a certificate (a plex.direct name, or a native hostname on
 * :32400) and [answers]; null otherwise.
 */
private suspend fun upgradeToHttps(candidate: PlexConnectionCandidate, answers: suspend (String) -> Boolean): PlexConnectionCandidate? {
    val current = candidate.url
    if (current.startsWith("https://")) return null
    var plexDirect = candidate.isPlexDirectUri
    val httpsUrl: String
    if (candidate.isPlexDirectUri) {
        if (!current.startsWith("http://")) return null
        httpsUrl = current.replaceFirst("http://", "https://")
    } else {
        // An IP literal can't present a certificate: its plex.direct alias can.
        val original = candidate.connection.uri
        httpsUrl = when {
            original.startsWith("https://") -> original
            original.startsWith("http://") -> original.replaceFirst("http://", "https://")
            else -> return null
        }
        val host = SimpleUri.parse(httpsUrl)?.host ?: return null
        if (host.lowercase().endsWith(".plex.direct")) {
            plexDirect = true
        } else if (!PlexServer.isNativePlexHostnameHttps(candidate.connection)) {
            return null
        }
    }
    if (httpsUrl == current || !answers(httpsUrl)) return null
    return PlexConnectionCandidate(candidate.connection.copy(protocol = "https", uri = httpsUrl), httpsUrl, plexDirect, true)
}

private fun selectBestCandidate(results: Map<PlexConnectionCandidate, ConnectionTestResult>): PlexConnectionCandidate? {
    fun best(entries: List<Map.Entry<PlexConnectionCandidate, ConnectionTestResult>>) = entries.sortedWith(
        compareBy<Map.Entry<PlexConnectionCandidate, ConnectionTestResult>> { it.key.connection.isIPv6 }
            .thenBy { !it.key.isHttps }
            .thenBy { it.value.latencyMs }
            .thenBy { !it.key.isPlexDirectUri },
    ).firstOrNull()?.key
    val entries = results.entries.toList()
    return best(entries.filter { it.key.connection.local && !it.key.connection.relay })
        ?: best(entries.filter { !it.key.connection.local && !it.key.connection.relay })
        ?: best(entries.filter { it.key.connection.relay })
}
